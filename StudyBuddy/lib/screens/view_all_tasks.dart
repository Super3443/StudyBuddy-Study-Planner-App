import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:flutter_riverpod/flutter_riverpod.dart'; // State management library
import 'package:intl/intl.dart'; // Formats task dates for display
import 'package:mbap_project/models/task_query.dart'; // Stores the selected Firestore query values
import 'package:mbap_project/providers/firebase_provider.dart'; // Provides Firestore task data
import 'package:mbap_project/providers/notification_provider.dart';
import 'package:mbap_project/providers/tags_provider.dart';
import 'package:mbap_project/providers/theme_provider.dart'; // Application theme colours and styling
import 'package:mbap_project/screens/settings.dart'; // Opens the settings screen
import 'package:mbap_project/widgets/edit_task_modal.dart'; // Opens the selected task for editing
import 'package:mbap_project/widgets/task_card.dart'; // Custom task card component


// The screen's widget, immutable, points to its state class below.
class AllTasksScreen extends ConsumerStatefulWidget {
  const AllTasksScreen({super.key});

  @override
  ConsumerState<AllTasksScreen> createState() => _AllTasksScreenState();
}

// Holds the selected filter values and the screen's UI logic.
class _AllTasksScreenState extends ConsumerState<AllTasksScreen> {
  // Starts by showing every task with the earliest date first.
  TaskQuery _taskQuery = const TaskQuery();

  // Tracks whether the user is in delete mode to remove tasks.
  bool _isDeleteMode = false;

  // Checks whether the user has applied a filter other than the default sort.
  bool get _hasActiveFilters {
    return _taskQuery.priority != null ||
        _taskQuery.tagName != null ||
        _taskQuery.completionFilter != TaskCompletionFilter.all ||
        _taskQuery.startDate != null ||
        _taskQuery.endDate != null ||
        _taskQuery.sortOrder != TaskSortOrder.earliestFirst;
  }

  // Opens the filter modal and saves its values after the user applies them.
  Future<void> _openTaskFilters() async {
    final selectedQuery = await showModalBottomSheet<TaskQuery>(
      context: context,
      isScrollControlled:
          true, // Gives the modal enough room for every filter control.
      backgroundColor:
          Colors.transparent, // Lets the modal use the app's dark background.
      builder: (context) => TaskFilterModal(initialQuery: _taskQuery),
    );

    // Stops when the modal was dismissed without applying a new query.
    if (selectedQuery == null || !mounted) return;

    // Rebuilds the provider watch with the newly selected filter values.
    setState(() => _taskQuery = selectedQuery);

    // Fetches fresh task and count results every time Apply Filters is pressed.
    ref.invalidate(filteredTasksProvider(selectedQuery));
  }

  // Resets every filter and returns the task list to its default date order.
  void _clearTaskFilters() {
    setState(() => _taskQuery = const TaskQuery());

    // Fetches a new unfiltered list instead of reusing an earlier default result.
    ref.invalidate(filteredTasksProvider(const TaskQuery()));
  }

  // Shows the delete confirmation dialog and removes the task if confirmed.
  Future<void> _confirmAndDeleteTask(String taskId) async {
    // Shows the same Delete Task prompt used in the edit modal.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkGreyColour, // Dark background matching the app theme
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Rounded corners matching the app's card design
        ),
        // Dialog title with a warning icon
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 24,
            ), // Red warning icon
            const SizedBox(width: 8), // Horizontal spacing between the icon and title text
            Text(
              'Delete Task',
              style: TextStyle(
                color: textPrimaryColour,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // Dialog message explaining the consequence of the action
        content: Text(
          'Are you sure you want to delete this task? This action cannot be undone.',
          style: TextStyle(color: textSecondaryColour, fontSize: 14),
        ),
        // Dialog action buttons
        actions: [
          // Cancel button — dismisses the dialog without deleting
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: accentColour),
            ),
          ),
          // Confirm delete button — returns true to proceed with deletion
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    // Stops when the user cancelled the dialog or dismissed it
    if (confirmed != true) return;

    try {
      // Deletes the task document from Firestore using the service provider
      await ref.read(firebaseServiceProvider).deleteTask(taskId);

      // Cancels the scheduled notification for the deleted task
      // Wrapped in try/catch so the delete completes even if cancellation fails
      try {
        await ref.read(notificationProvider).cancelNotification(taskId.hashCode);
      } catch (_) {
        // Continues when notification cancellation fails
      }

      // Stops safely when the screen was closed during the Firestore delete
      if (!mounted) return;

      // Reloads the filtered task list after the deletion
      await _refreshTaskResults();
    } catch (_) {
      // Stops when the All Tasks screen has been removed
      if (!mounted) return;

      // Shows feedback when Firestore cannot delete the task
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete the task. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Reloads the task list and count for the current filters
  Future<void> _refreshTaskResults() async {
    // Removes the saved filtered task result
    ref.invalidate(filteredTasksProvider(_taskQuery));

    // Removes the saved task count result

    try {
      // Waits for the refreshed task list and count
      await ref.read(filteredTasksProvider(_taskQuery).future); // Loads the refreshed tasks

    } catch (_) {
      // The providers display their own loading errors
    }
  }

  @override
  // Builds the visual layout of the screen.
  Widget build(BuildContext context) {
    ref.watch(themeProvider); // Rebuilds when the colour scheme changes
    
    // Fetches tasks from Firestore and applies the selected filters locally.
    final tasks = ref.watch(filteredTasksProvider(_taskQuery));

    return SafeArea(
      // Prevents UI elements from overlapping with device status bars and notches.
      child: Column(
        // Column layout for the screen's content.
        crossAxisAlignment: CrossAxisAlignment
            .start, // Aligns all child elements to the left edge.
        children: [
          // --- HEADER SECTION ---
          Padding(
            padding: const EdgeInsets.fromLTRB(24,16,24,8), // Adds space around the header.
            child: Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceBetween, // Keeps the title and settings icon apart.
              children: [
                Text(
                  'StudyBuddy',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColour,
                  ),
                ),
                // Wraps the settings icon to make it tappable.
                GestureDetector(
                  onTap: () {
                    // Opens the Settings screen when tapped.
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
          Divider(
            color: dividerColour,
          ), // Separates the header from the task content.

          // --- SCREEN TITLE ---
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 10), // Adds space around the screen title.
            child: Row(
              children: [
                // Screen title taking up remaining horizontal space
                Expanded(
                  child: Text(
                    'View All Tasks',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: textPrimaryColour,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                // Toggles delete mode on and off for quick task removal
                OutlinedButton.icon(
                  onPressed: () => setState(() => _isDeleteMode = !_isDeleteMode), // Flips the delete mode state
                  icon: Icon(
                    _isDeleteMode
                        ? Icons.close // Shows X icon when delete mode is active
                        : Icons.delete_outline, // Shows bin icon when delete mode is inactive
                    size: 18,
                  ),
                  label: Text(
                    _isDeleteMode
                        ? 'Cancel' // Label when delete mode is active
                        : 'Delete', // Label when delete mode is inactive
                  ),
                  style: OutlinedButton.styleFrom(
                    // Switches between red and accent depending on the mode
                    foregroundColor: _isDeleteMode ? Colors.redAccent : accentColour,
                    side: BorderSide(
                      color: _isDeleteMode
                          ? Colors.redAccent.withValues(alpha: 0.7) // Red border in delete mode
                          : accentColour.withValues(alpha: 0.7), // Accent border in normal mode
                      width: 2.5, // Slightly thicker outline
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                  ),
                ),
                // Horizontal spacing between the delete and filter buttons
                const SizedBox(width: 8),
                // Opens the modal where filters and date order can be selected
                OutlinedButton.icon(
                  onPressed: _openTaskFilters,
                  icon: const Icon(Icons.tune_rounded, size: 18), // Filter icon
                  label: const Text('Filter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accentColour, // Accent text and icon colour
                    side: BorderSide(color: accentColour.withValues(alpha: 0.7), width: 2.5), // Accent border with increased thickness
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),

          // Shows the filtered task count and the reset action when needed.
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
            child: Row(
              children: [
                Expanded(
                  child: tasks.when(
                    // Displays the number of tasks matching the selected filters.
                    data: (taskList) => Text(
                      '${taskList.length} ${taskList.length == 1 ? 'matching task' : 'matching tasks'}',
                      style: TextStyle(
                        color: textSecondaryColour,
                        fontSize: 15,
                      ),
                    ),
                    // Keeps the summary area stable while tasks are loading.
                    loading: () => Text(
                      'Updating task count...',
                      style: TextStyle(
                        color: textSecondaryColour,
                        fontSize: 15,
                      ),
                    ),
                    // Shows a safe message when tasks cannot be loaded.
                    error: (_, _) => Text(
                      'Task count unavailable',
                      style: TextStyle(
                        color: textSecondaryColour,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                // Lets the user quickly remove every selected filter and sort choice.
                if (_hasActiveFilters)
                  TextButton(
                    onPressed: _clearTaskFilters,
                    style: TextButton.styleFrom(foregroundColor: accentColour),
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),

          // --- MAIN TASK LIST ---
          Expanded(
            child: tasks.when(
              // Builds the task list after the filtered task data loads.
              data: (taskList) {
                // Explains whether there are no saved tasks or no matching filtered tasks.
                if (taskList.isEmpty) {
                  return Center(
                    child: Text(
                      _hasActiveFilters
                          ? 'No tasks match the selected filters.'
                          : 'No tasks have been created yet.',
                      style: TextStyle(color: textSecondaryColour),
                    ),
                  );
                }

                // Builds one task card for every Firestore task returned by the query.
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24,0,24,90), // Leaves space around the task list.
                  itemCount: taskList.length, // Uses the number of tasks after filtering.
                  itemBuilder: (context, index) {
                    // Gets the current task from the Firestore task list.
                    final task = taskList[index];

                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 13,
                      ), // Adds space below each task card.
                      child: TaskCard(
                        title: task.title, // Displays the saved task title.
                        category:
                            task.tagName, // Displays the optional saved tag.
                        date: DateFormat('d MMMM yyyy').format(
                          task.startDate,
                        ), // Formats the saved task date.
                        time:
                            '${TimeOfDay.fromDateTime(task.startDate).format(context)} - '
                            '${TimeOfDay.fromDateTime(task.endDate).format(context)}', // Formats the saved task times.
                        priority: task.priority,
                        isDeleteMode: _isDeleteMode, // Passes the current delete mode state to the card
                        isCompleted:
                            task.isCompleted, // Displays the saved completion status.
                        // Opens the edit modal with the selected Firestore task.
                        onEdit: () async {
                          // Waits for the edit modal to report a saved change
                          final taskChanged = await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled:
                                true, // Keeps the modal above the keyboard.
                            backgroundColor: Colors
                                .transparent, // Lets the modal use its custom background.
                            builder: (context) => Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(
                                  context,
                                ).viewInsets.bottom,
                              ),
                              child: EditTaskModal(task: task),
                            ),
                          );

                          // Stops when the modal closes without changing the task
                          if (taskChanged != true || !mounted) return;

                          // Reloads the current filtered task results
                          await _refreshTaskResults();
                        },

                        // In delete mode: taps the icon to delete the task
                        // In normal mode: taps the icon to toggle task completion
                        onToggle: _isDeleteMode
                            // Runs the delete confirmation when in delete mode
                            ? () => _confirmAndDeleteTask(task.taskId)
                            // Toggles the task completion status in Firestore
                            : () async {
                                try {
                                  // Updates the completion status in the matching Firestore task
                                  await ref
                                      .read(firebaseServiceProvider)
                                      .updateTaskCompletion(
                                        taskId: task.taskId,
                                        isCompleted: !task.isCompleted,
                                      );
                                } catch (_) {
                                  // Stops when the All Tasks screen has been removed
                                  if (!context.mounted) return;

                                  // Shows feedback when Firestore cannot save the completion change
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Unable to update the task. Please try again.',
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );

                                  // Stops because Firestore did not save the completion change
                                  return;
                                }

                                // Stops safely when the screen was closed during the Firestore update
                                if (!mounted) return;

                                // Reloads the filtered tasks after the saved change
                                await _refreshTaskResults();
                              },
                      ),
                    );
                  },
                );
              },

              // Shows a progress indicator while the task data is loading.
              loading: () => const Center(child: CircularProgressIndicator()),

              // Shows a safe message when the task data cannot load.
              error: (_, _) => Center(
                child: Text(
                  'Unable to load tasks. Please try again.',
                  style: TextStyle(color: textSecondaryColour),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Lets the user choose the filter and sort values applied to the task list.
class TaskFilterModal extends ConsumerStatefulWidget {
  // Receives the previously applied values so they remain visible when reopening the modal.
  final TaskQuery initialQuery;

  const TaskFilterModal({super.key, required this.initialQuery});

  @override
  ConsumerState<TaskFilterModal> createState() => _TaskFilterModalState();
}

// Holds temporary filter choices until the user applies them.
class _TaskFilterModalState extends ConsumerState<TaskFilterModal> {
  late TaskCompletionFilter _completionFilter;
  late int? _selectedPriority;
  late String? _selectedTag;
  late TaskSortOrder _sortOrder;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();

    // Copies the applied values so cancelling does not change the task list.
    _completionFilter = widget.initialQuery.completionFilter;
    _selectedPriority = widget.initialQuery.priority;
    _selectedTag = widget.initialQuery.tagName;
    _sortOrder = widget.initialQuery.sortOrder;

    // Converts the saved exclusive end date back into the visible final date.
    if (widget.initialQuery.startDate != null &&
        widget.initialQuery.endDate != null) {
      _selectedDateRange = DateTimeRange(
        start: widget.initialQuery.startDate!,
        end: widget.initialQuery.endDate!.subtract(const Duration(days: 1)),
      );
    }
  }

  // Opens the calendar where the first and last date can be chosen together.
  Future<void> _pickDateRange() async {
    final selectedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        // Applies theme-aware colours to the date range picker
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme(
              brightness: Brightness.dark, // Keeps the picker in dark mode
              primary: accentColour, // Selected date highlight
              onPrimary: blackColour, // Text on the selected date
              secondary: accentColour, // Range fill colour
              onSecondary: blackColour, // Text on the range fill
              surface: darkGreyColour, // Picker background
              onSurface: textPrimaryColour, // Calendar day text
              error: Colors.redAccent, // Validation error colour
              onError: textPrimaryColour, // Text on error
            ),
          ),
          child: child!,
        );
      },
    );

    // Stops when the date picker closes without a selected date range.
    if (selectedRange == null || !mounted) return;

    // Saves the selected dates until the user applies the modal filters.
    setState(() => _selectedDateRange = selectedRange);
  }

  // Removes every temporary value without changing the query until Apply is tapped.
  void _clearTemporaryFilters() {
    setState(() {
      _completionFilter = TaskCompletionFilter.all;
      _selectedPriority = null;
      _selectedTag = null;
      _selectedDateRange = null;
      _sortOrder = TaskSortOrder.earliestFirst;
    });
  }

  // Returns a full-day DateTime for the first selected day.
  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  // Returns the following day so the date filter includes the selected final day.
  DateTime _dayAfter(DateTime date) =>
      DateTime(date.year, date.month, date.day + 1);

  // Converts the temporary choices into the filter query applied to the task list.
  void _applyFilters() {
    Navigator.pop(
      context,
      TaskQuery(
        priority: _selectedPriority,
        tagName: _selectedTag,
        completionFilter: _completionFilter,
        startDate: _selectedDateRange == null
            ? null
            : _startOfDay(_selectedDateRange!.start),
        endDate: _selectedDateRange == null
            ? null
            : _dayAfter(_selectedDateRange!.end),
        sortOrder: _sortOrder,
      ),
    );
  }

  // Formats the selected date range into a compact readable label.
  String _dateRangeLabel() {
    if (_selectedDateRange == null) return 'All dates';

    final format = DateFormat('d MMM yyyy');
    return '${format.format(_selectedDateRange!.start)} - ${format.format(_selectedDateRange!.end)}';
  }

  // Builds the small label above each filter field.
  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: accentColour,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // Builds the shared dark border used around the dropdown controls.
  InputDecoration _dropdownDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: unselectedNavColour),
      filled: true,
      fillColor: blackColour,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gets the user's Firestore tags, defaulting to an empty list while loading
    final userTags = ref.watch(tagsProvider).asData?.value ?? [];
    return Container(
      decoration: BoxDecoration(
        color: darkGreyColour,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shows the small handle used to drag the modal down.
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Keeps the modal title and clear action on the same line.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter & Sort Tasks',
                      style: TextStyle(
                        color: textPrimaryColour,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearTemporaryFilters,
                    style: TextButton.styleFrom(foregroundColor: accentColour),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- COMPLETION STATUS ---
              _buildFieldLabel('Completion Status'),
              const SizedBox(height: 8),
              DropdownButtonFormField<TaskCompletionFilter>(
                initialValue: _completionFilter,
                dropdownColor: blackColour,
                style: TextStyle(color: textPrimaryColour),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: textSecondaryColour,
                ),
                decoration: _dropdownDecoration('All tasks'),
                items: const [
                  DropdownMenuItem(
                    value: TaskCompletionFilter.all,
                    child: Text('All tasks'),
                  ),
                  DropdownMenuItem(
                    value: TaskCompletionFilter.incomplete,
                    child: Text('Incomplete'),
                  ),
                  DropdownMenuItem(
                    value: TaskCompletionFilter.completed,
                    child: Text('Completed'),
                  ),
                ],
                // Changes the temporary status filter without applying it yet.
                onChanged: (value) {
                  if (value != null) setState(() => _completionFilter = value);
                },
              ),
              const SizedBox(height: 18),

              // --- TAG FILTER ---
              _buildFieldLabel('Tag'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _selectedTag,
                dropdownColor: blackColour,
                style: TextStyle(color: textPrimaryColour),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: textSecondaryColour,
                ),
                decoration: _dropdownDecoration('All tags'),
                items: [
                  // Default option showing all tags without filtering
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All tags'),
                  ),
                  // Always includes Generated so AI-created tasks can be filtered
                  const DropdownMenuItem<String?>(
                    value: 'Generated',
                    child: Text('Generated'),
                  ),
                  // Loads the user's Firestore tags from the tags provider
                  ...userTags.map(
                    (tag) => DropdownMenuItem<String?>(value: tag, child: Text(tag)),
                  ),
                ],
                // Changes the temporary subject tag without applying it yet.
                onChanged: (value) => setState(() => _selectedTag = value),
              ),
              const SizedBox(height: 18),

              // --- PRIORITY FILTER ---
              _buildFieldLabel('Priority'),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                initialValue: _selectedPriority,
                dropdownColor: blackColour,
                style: TextStyle(color: textPrimaryColour),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: textSecondaryColour,
                ),
                decoration: _dropdownDecoration('All priorities'),
                items: const [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All priorities'),
                  ),
                  DropdownMenuItem<int?>(value: 1, child: Text('Low')),
                  DropdownMenuItem<int?>(value: 2, child: Text('Medium')),
                  DropdownMenuItem<int?>(value: 3, child: Text('High')),
                ],
                // Changes the temporary priority without applying it yet.
                onChanged: (value) => setState(() => _selectedPriority = value),
              ),
              const SizedBox(height: 18),

              // --- DATE RANGE FILTER ---
              _buildFieldLabel('Task Date Range'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDateRange,
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: blackColour,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range_outlined,
                        color: textSecondaryColour,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _dateRangeLabel(),
                          style: TextStyle(color: textPrimaryColour),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: textSecondaryColour,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // --- SORT ORDER ---
              _buildFieldLabel('Sort by Date'),
              const SizedBox(height: 8),
              DropdownButtonFormField<TaskSortOrder>(
                initialValue: _sortOrder,
                dropdownColor: blackColour,
                style: TextStyle(color: textPrimaryColour),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: textSecondaryColour,
                ),
                decoration: _dropdownDecoration('Earliest first'),
                items: const [
                  DropdownMenuItem(
                    value: TaskSortOrder.earliestFirst,
                    child: Text('Earliest first'),
                  ),
                  DropdownMenuItem(
                    value: TaskSortOrder.latestFirst,
                    child: Text('Latest first'),
                  ),
                ],
                // Changes the temporary sort direction.
                onChanged: (value) {
                  if (value != null) setState(() => _sortOrder = value);
                },
              ),
              const SizedBox(height: 28),

              // Applies all selected filter and sort values to the task list.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _applyFilters,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Apply Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColour,
                    foregroundColor: blackColour,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
