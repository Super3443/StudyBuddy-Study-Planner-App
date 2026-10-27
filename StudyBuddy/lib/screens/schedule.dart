import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:flutter_riverpod/flutter_riverpod.dart'; // State management library
import 'package:mbap_project/screens/settings.dart';
import 'package:mbap_project/widgets/task_card.dart'; // Custom task card widget
import 'package:mbap_project/providers/theme_provider.dart'; // Application theme colours and styling
import 'package:intl/intl.dart'; // Formats the current date for the schedule heading
import 'package:mbap_project/providers/firebase_provider.dart'; // Provides the Firestore task stream
import 'package:mbap_project/widgets/edit_task_modal.dart'; // Opens the selected task for editing
import 'package:mbap_project/models/study_task.dart'; // Defines the Firestore task data used by the calendar
import 'package:table_calendar/table_calendar.dart'; // Displays the interactive monthly calendar

// The screen's widget, immutable, points to its state class below
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

// Holds the mutable state and UI logic for the Schedule screen
class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  // Keeps the visible calendar month after the user swipes between months.
  DateTime _focusedDay = DateTime.now();

  // Starts by selecting today so the task list opens with today's schedule.
  DateTime _selectedDay = DateTime.now();

  // Builds the calendar and adds a marker to every date containing a Firestore task.
  Widget _buildCalendar(List<StudyTask> taskList) {
    return TableCalendar<StudyTask>(
      // Limits the calendar to a practical study-planning date range.
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2035, 12, 31),

      // Keeps the currently visible month when this screen rebuilds.
      focusedDay: _focusedDay,

      // Highlights the date whose tasks are currently displayed below the calendar.
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

      // Returns tasks on the same date so TableCalendar can show event markers.
      eventLoader: (day) {
        return taskList.where((task) => isSameDay(task.startDate, day)).toList();
      },

      // Updates the selected date and keeps the selected month visible.
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },

      // Stores the new month so a later rebuild does not jump back to today.
      onPageChanged: (focusedDay) => _focusedDay = focusedDay,

      // Keeps the schedule screen focused on a clear monthly calendar.
      calendarFormat: CalendarFormat.month,
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},

      // Styles the month header and navigation arrows to match the app colours.
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(
          color: textPrimaryColour,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        leftChevronIcon: Icon(Icons.chevron_left, color: accentColour),
        rightChevronIcon: Icon(Icons.chevron_right, color: accentColour),
      ),

      // Styles the weekday labels with the colour palette.
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: textSecondaryColour),
        weekendStyle: TextStyle(color: accentColour.withValues(alpha: 0.8)),
      ),

      // Styles dates, selections and task markers to match the rest of the app.
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        defaultDecoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(12),
        ),
        weekendDecoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(12),
        ),
        outsideDecoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(12),
        ),
        selectedDecoration: BoxDecoration(
          color: highlightColour,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: highlightColour.withValues(alpha: 0.45),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        // The number on selected data is black
        selectedTextStyle: TextStyle(
          color: blackColour, 
          fontWeight: FontWeight.bold,
        ), 
        todayDecoration: BoxDecoration(
          color: darkGreyColour,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColour.withValues(alpha: 0.7),
          ),
        ),
        todayTextStyle: TextStyle(color: accentColour, fontWeight: FontWeight.bold),
        markerDecoration: BoxDecoration(color: accentColour, shape: BoxShape.circle),
        markersMaxCount: 1,
        markersAlignment: Alignment.bottomCenter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider); // Rebuilds when the colour scheme changes

    // Watches the Firestore task stream for real-time task updates.
    final tasks = ref.watch(tasksProvider);

    // Formats the date currently selected from the calendar for the schedule heading.
    final formattedDate = DateFormat('EEEE, d MMMM').format(_selectedDay);
    
    return SafeArea( // Prevents UI elements from overlapping with device status bars and notches
      child: Column( // Column layout for the screen's content
        children: [
          // --- HEADER SECTION ---
          // Applies padding around the header elements
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8), // 24 pixels on the left/right, 16 pixels on top, 8 pixels on the bottom
            // Arranges the title and settings icon horizontally
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Pushes the title to the left and the settings icon to the right
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
                // Forces the divider to span the entire available horizontal space
                Expanded(
                  child: Divider(color: dividerColour) // Horizontal line using white with 6% opacity
                ),
              ],
            ),

            // --- MAIN CONTENT ---
            // Forces the scrollable area to fill all remaining vertical space
            Expanded(
              child: SingleChildScrollView( // Allows the user to scroll through the schedule and tasks
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8), // 24 pixels on the left/right, 8 pixels on top, 8 pixels on the bottom
                // Aligns all content to the left edge of the screen
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Builds the calendar with markers after Firestore returns the user's tasks.
                    tasks.when(
                      // Adds a marker to every calendar date that contains a saved task.
                      data: _buildCalendar,

                      // Keeps the calendar visible while Firestore loads the task markers.
                      loading: () => _buildCalendar(const <StudyTask>[]),

                      // Keeps the calendar usable when the Firestore task request fails.
                      error: (_, _) => _buildCalendar(const <StudyTask>[]),
                    ),

                    // Vertical spacing before the Date Header Row
                    const SizedBox(height: 32),

                    // --- SELECTED DATE'S SCHEDULE ---
                    // Shows Firestore tasks planned for the selected calendar date.
                    tasks.when(
                      // Builds the schedule after Firestore returns the task data.
                      data: (taskList) {
                        // Keeps only tasks planned to start on the selected calendar date.
                        final selectedDateTasks = taskList
                            .where((task) => isSameDay(task.startDate, _selectedDay))
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // Aligns the schedule content to the left
                          children: [
                            // Arranges the selected date and task count on one row.
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Separates the date and task count
                              children: [
                                Text(
                                  formattedDate, // Displays the selected formatted date
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimaryColour,
                                  ),
                                ),

                                // Shows the number of tasks planned for the selected date.
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Shapes the task-count pill
                                  decoration: BoxDecoration(
                                    color: darkGreyColour,
                                    borderRadius: BorderRadius.circular(20), // Rounds the task-count pill
                                    border: Border.all(color: borderColour), // Adds a faint border
                                  ),
                                  child: Text(
                                    '${selectedDateTasks.length} tasks', // Displays the selected date's Firestore task count
                                    style: TextStyle(
                                      color: accentColour.withValues(alpha: 0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16), // Adds space before the task list

                            // Shows a message when no Firestore tasks are planned for the selected date.
                            if (selectedDateTasks.isEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  'No tasks scheduled for this date.',
                                  style: TextStyle(color: textSecondaryColour),
                                ),
                              ),

                            // Builds a task card for every Firestore task planned for the selected date.
                            ...selectedDateTasks.map((task) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 13), // Adds space below each task card
                                child: TaskCard(
                                  title: task.title, // Displays the saved task title
                                  category: task.tagName, // Displays the optional saved tag
                                  date: DateFormat('d MMMM yyyy').format(task.startDate), // Formats the saved task date
                                  time: '${TimeOfDay.fromDateTime(task.startDate).format(context)} - '
                                      '${TimeOfDay.fromDateTime(task.endDate).format(context)}', // Formats the saved task times
                                  priority: task.priority,
                                  isCompleted: task.isCompleted, // Displays the saved completion status

                                  // Opens the edit modal with the selected Firestore task.
                                  onEdit: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true, // Keeps the modal above the keyboard
                                      backgroundColor: Colors.transparent, // Lets the modal use its custom background
                                      builder: (context) => Padding(
                                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                        child: EditTaskModal(task: task),
                                      ),
                                    );
                                  },

                                  // Updates the completion status in the matching Firestore task.
                                  onToggle: () async {
                                    try {
                                      await ref.read(firebaseServiceProvider).updateTaskCompletion(
                                        taskId: task.taskId,
                                        isCompleted: !task.isCompleted,
                                      );
                                    } catch (_) {
                                      // Stops when the Schedule screen has been removed.
                                      if (!context.mounted) return;

                                      // Shows feedback when Firestore cannot save the completion change.
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Unable to update the task. Please try again.'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            }),
                          ],
                        );
                      },

                      // Shows a progress indicator while Firestore is loading the schedule.
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        ),
                      ),

                      // Shows a safe message when Firestore cannot load the schedule.
                      error: (_, _) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Unable to load the schedule. Please try again.',
                            style: TextStyle(color: textSecondaryColour),
                          ),
                        ),
                      ),
                    ),

                    // Extra space at bottom to prevent content from being hidden by the floating action button
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
