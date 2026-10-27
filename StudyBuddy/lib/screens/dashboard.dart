import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:flutter_riverpod/flutter_riverpod.dart'; // State management library
import 'package:intl/intl.dart'; // Formats task dates for display
import 'package:mbap_project/providers/firebase_provider.dart';
import 'package:mbap_project/screens/analytics.dart';
import 'package:mbap_project/screens/settings.dart';
import 'package:mbap_project/widgets/edit_task_modal.dart'; // Opens the selected task for editing
import 'package:mbap_project/widgets/progress_card.dart';
import 'package:mbap_project/widgets/task_card.dart';
import 'package:mbap_project/providers/theme_provider.dart';

// The screen's widget, immutable, points to its state class below
class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenTasks; // Opens the Tasks tab from the dashboard
  final VoidCallback onOpenAI; // Opens the AI tab from the dashboard

  const DashboardScreen({
    super.key,
    required this.onOpenTasks,
    required this.onOpenAI,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

// Holds the mutable state and UI logic for the Dashboard screen
class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Checks whether a task date belongs to the current calendar day.
  bool _isToday(DateTime taskDate, DateTime today) {
    return taskDate.year == today.year &&
        taskDate.month == today.month &&
        taskDate.day == today.day;
  }

  // Formats the total scheduled minutes into a short dashboard label.
  String _formatStudyTime(int totalMinutes) {
    final hours = totalMinutes ~/ 60; // Keeps the completed whole hours
    final minutes =
        totalMinutes % 60; // Keeps the minutes left after whole hours

    // Shows only minutes when the planned time is under one hour.
    if (hours == 0) return '${minutes}m';

    // Shows only hours when there are no remaining minutes.
    if (minutes == 0) return '${hours}h';

    // Shows both values when the schedule includes hours and minutes.
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider); // Rebuilds when the colour scheme changes
    
    // Fetches the current user to display their name dynamically
    final currentUser = ref.watch(authStateProvider).value;

    // Watches the Firestore task stream for real-time task update
    final tasks = ref.watch(tasksProvider);

    // Removes the current time so every task uses the same date comparison.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return SafeArea(
      // Prevents UI elements from overlapping with device status bars
      child: Column(
        // Column layout for the screen's content
        crossAxisAlignment: CrossAxisAlignment
            .start, // Aligns all child elements to the left edge of the screen
        children: [
          // --- HEADER SECTION ---
          // Applies padding around the header elements
          Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              16,
              24,
              8,
            ), // 24 pixels on the left/right, 16 pixels on top, 8 pixels on the bottom
            // Arranges the title and settings icon horizontally
            child: Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceBetween, // Pushes the title to the left and the settings icon to the right
              children: [
                Text(
                  'StudyBuddy',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColour,
                  ),
                ),
                // Wraps the settings icon to make it tappable
                GestureDetector(
                  onTap: () {
                    // Navigates to the Settings screen when tapped
                    Navigator.pushNamed(context, SettingsScreen.routeName);
                  },
                  child: Icon(
                    Icons.settings_outlined,
                    color: textSecondaryColour,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // --- DIVIDER ---
          // Wraps the divider in a row to structure the layout width
          Row(
            children: [
              // Forces the divider to span the entire horizontal space
              Expanded(
                child: Divider(
                  color: dividerColour,
                ), // Faint horizontal line separating the header from the content
              ),
            ],
          ),

          // --- MAIN DASHBOARD ---
          // Forces the scrollable area to fill all remaining vertical space
          Expanded(
            // Allows the dashboard content to scroll vertically
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24,8,24,8,), // 24 pixels on the left/right, 8 pixels on the top/bottom
              child: Column(
                // Aligns all content to the left edge of the screen
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- GREETING SECTION ---
                  // Displays the user's name or defaults to 'User' if null
                  Text(
                    'Hello, ${currentUser?.displayName ?? 'User'}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textPrimaryColour,
                    ),
                  ),

                  // Vertical spacing before the subtitle
                  const SizedBox(height: 2),

                  // Subtitle greeting text
                  Text(
                    "Let's make today productive!",
                    style: TextStyle(
                      color: accentColour,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),

                  // Vertical spacing before the Progress card
                  const SizedBox(height: 24),

                  // --- PROGRESS CARD ---
                  // Builds the daily progress values from the same Firestore task stream.
                  tasks.when(
                    data: (taskList) {
                      // Keeps only tasks that are scheduled for the current day.
                      final todayTasks = taskList
                          .where((task) => _isToday(task.startDate, today))
                          .toList();

                      // Counts the tasks that have already been marked as complete.
                      final completedTaskCount = todayTasks
                          .where((task) => task.isCompleted)
                          .length;

                      // Avoids dividing by zero when the user has no tasks today.
                      final progress = todayTasks.isEmpty
                          ? 0.0
                          : completedTaskCount / todayTasks.length;

                      // Adds the duration of every scheduled task for today.
                      final totalScheduledMinutes = todayTasks.fold<int>(0, (
                        total,
                        task,
                      ) {
                        // Ignores invalid negative durations to keep the summary safe.
                        final minutes = task.endDate
                            .difference(task.startDate)
                            .inMinutes;
                        return total + (minutes > 0 ? minutes : 0);
                      });

                      return Column(
                        children: [
                          ProgressCard(
                            progress:
                                progress, // Fills the ring using completed tasks
                            studyTime: _formatStudyTime(
                              totalScheduledMinutes,
                            ), // Shows today's planned duration
                            tasksDone:
                                '$completedTaskCount/${todayTasks.length}', // Shows completed tasks out of today's total
                          ),

                          const SizedBox(height: 16), // Adds space before the analytics button

                          // Opens the study analytics screen.
                          SizedBox(
                            width: double.infinity, // Stretches the button to full width
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Navigates to the analytics screen.
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AnalyticsScreen()), // Opens the analytics screen
                                );
                              },
                              icon: Icon(Icons.bar_chart_rounded, size: 26), // Displays the chart icon
                              label: const Text(
                                'View Analytics',
                                style: TextStyle(fontSize: 16), // Sets the button label size
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accentColour, // Sets the accent text colour
                                side: BorderSide(color: accentColour.withValues(alpha: 0.4), width: 3), // Sets the border colour and thickness
                                padding: const EdgeInsets.symmetric(vertical: 14), // Adds vertical padding
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16), // Rounds the button corners
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    // Shows progress-card feedback while the task stream loads.
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    // Shows progress-card feedback when Firestore cannot load tasks.
                    error: (error, _) => Text(
                      'Unable to load progress: $error',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),

                  // Verticle spacing before the Generate Optimal Schedule Button
                  const SizedBox(height: 24),

                  // --- GENERATE OPTIMAL SCHEDULE BUTTON ---
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColour,
                      minimumSize: const Size.fromHeight(
                        70,
                      ), // Forces the button to stretch across the full width and be 70 pixels tall
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          40,
                        ), // Rounded corners to the button
                      ),
                      // Adds a slight drop shadow
                      elevation: 4,
                    ),
                    // Switches the active bottom navigation tab to the AI Assistant screen
                    onPressed: widget.onOpenAI,
                    child: Row(
                      // Centers the icon and text together horizontally inside the button
                      mainAxisAlignment: MainAxisAlignment
                          .center, // Centers the content inside horizontally
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: deepAccentColour,
                          size: 22,
                        ),
                        SizedBox(
                          width: 12,
                        ), // Horizontal spacing between icon and text
                        Text(
                          'Generate Optimal Schedule',
                          style: TextStyle(
                            color: deepAccentColour,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Vertical spacing before the Tasks
                  const SizedBox(height: 32),

                  // --- TASKS HEADER ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // Pushes the section title to the left and the "View All" link to the right
                    children: [
                      // Section label with spaced lettering
                      Text(
                        "TODAY'S TASKS",
                        style: TextStyle(
                          color: unselectedNavColour,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.5,
                        ),
                      ),
                      // Wraps the text to make it tappable
                      GestureDetector(
                        // Switches the active bottom navigation tab to the All Tasks screen
                        onTap: widget.onOpenTasks,
                        child: Text(
                          'View All >',
                          style: TextStyle(
                            color: textPrimaryColour,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Vertical spacing before the Tasks List
                  const SizedBox(height: 16),

                  // --- TASK LIST ---
                  // Displays the task list based on the current Firestore stream state
                  tasks.when(
                    // Runs when Firestore task data has loaded successfully
                    data: (taskList) {
                      // Filters the Firestore tasks to include only tasks starting today
                      final todayTasks = taskList.where((task) {
                        return _isToday(task.startDate, today);
                      }).toList();

                      // Shows a message when no tasks are planned for today
                      if (todayTasks.isEmpty) {
                        return Padding(
                          // Adds space around the empty-task message
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No tasks scheduled for today.',
                            // Uses a faded colour to keep the message subtle
                            style: TextStyle(color: textSecondaryColour),
                          ),
                        );
                      }

                      // Builds a task card for every Firestore task planned for today
                      return Column(
                        // Converts every task object into a visible task card
                        children: todayTasks.map((task) {
                          return Padding(
                            // Adds spacing below each task card
                            padding: const EdgeInsets.only(bottom: 13),
                            child: TaskCard(
                              // Displays the task title saved in Firestore
                              title: task.title,

                              // Displays the optional tag when one was selected
                              category: task.tagName,

                              // Formats the saved date for the task card
                              date: DateFormat(
                                'd MMMM yyyy',
                              ).format(task.startDate),

                              // Formats the saved start and end times for the task card
                              time:
                                  '${TimeOfDay.fromDateTime(task.startDate).format(context)} - '
                                  '${TimeOfDay.fromDateTime(task.endDate).format(context)}',
                                  
                              priority: task.priority,

                              // Displays the completion status saved in Firestore
                              isCompleted: task.isCompleted,

                              // Opens the edit modal with the selected Firestore task.
                              onEdit: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled:
                                      true, // Keeps the modal above the keyboard
                                  backgroundColor: Colors
                                      .transparent, // Lets the modal use its custom background
                                  builder: (context) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(
                                        context,
                                      ).viewInsets.bottom,
                                    ),
                                    child: EditTaskModal(task: task),
                                  ),
                                );
                              },

                              // Updates the completion status in the matching Firestore task.
                              onToggle: () async {
                                try {
                                  await ref
                                      .read(firebaseServiceProvider)
                                      .updateTaskCompletion(
                                        taskId: task.taskId,
                                        isCompleted: !task.isCompleted,
                                      );
                                } catch (_) {
                                  // Stops when the Dashboard has been removed from the screen.
                                  if (!context.mounted) return;

                                  // Shows feedback when Firestore cannot save the completion change.
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Unable to update the task. Please try again.',
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },

                    // Shows a loading spinner while Firestore retrieves tasks
                    loading: () => const Padding(
                      // Adds space around the loading spinner
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        // Shows that task data is still being retrieved
                        child: CircularProgressIndicator(),
                      ),
                    ),

                    // Shows an error message when Firestore cannot retrieve tasks
                    error: (error, _) => Padding(
                      // Adds space around the error message
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Unable to load tasks: $error',
                        // Uses red to make the error message clear
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),

                  // Extra space at bottom to prevent tasks from being hidden by the floating action button
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
