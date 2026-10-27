import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:flutter_riverpod/flutter_riverpod.dart'; // State management library
import 'package:intl/intl.dart'; // Formats the selected task date
import 'package:mbap_project/models/study_task.dart'; // Contains the selected Firestore task data
import 'package:mbap_project/providers/firebase_provider.dart'; // Provides the Firebase service
import 'package:mbap_project/providers/theme_provider.dart'; // Application theme colours and styling
import 'package:mbap_project/providers/notification_provider.dart';
import 'package:mbap_project/providers/tags_provider.dart'; // Provides the user's Firestore tag list
import 'package:mbap_project/widgets/manage_tags_dialog.dart'; // Shared tag management dialog and noTagOption constant

// The modal's widget, immutable, points to its state class below
class EditTaskModal extends ConsumerStatefulWidget {
  // Stores the selected Firestore task for pre-filling the form.
  final StudyTask task;

  const EditTaskModal({super.key, required this.task});

  @override
  ConsumerState<EditTaskModal> createState() => _EditTaskModalState();
}

// Holds the mutable state and UI logic for the Edit Task modal form
class _EditTaskModalState extends ConsumerState<EditTaskModal> {
  // Global key to identify and validate the form
  final _formKey = GlobalKey<FormState>();

  // Identifies the custom start time field so its paired end-time error can refresh.
  final _startTimeFieldKey = GlobalKey<FormFieldState<TimeOfDay>>();

  // Identifies the custom end time field so the comparison appears inside the form.
  final _endTimeFieldKey = GlobalKey<FormFieldState<TimeOfDay>>();

  late String _taskName; // Stores the validated task name

  // Stores the selected date and times for the edited task.
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  late String _selectedTag;

  // Tracks the currently selected priority level
  late String _selectedPriority;

  // Local state variables to track the loading status of each button independently
  bool _isSaving = false; // True while the save operation is in progress
  bool _isDeleting = false; // True while the delete operation is in progress

  @override
  // Initialises the form fields with the existing task data passed in from the constructor
  void initState() {
    super.initState();
    _taskName = widget.task.title; // Pre-fills the saved task title
    _selectedDate = widget.task.startDate; // Pre-selects the saved task date
    _startTime = TimeOfDay.fromDateTime(widget.task.startDate); // Pre-selects the saved start time
    _endTime = TimeOfDay.fromDateTime(widget.task.endDate); // Pre-selects the saved end time
    _selectedTag = widget.task.tagName ?? noTagOption; // Uses the optional tag choice when no tag was saved
    _selectedPriority = _priorityLabel(widget.task.priority); // Converts the saved number into a visible label
    // Fetches the latest task data from Firestore to demonstrate select-one.
    _refreshFromFirestore();
  }

  // Reads the single task document from Firestore and updates the form fields.
  Future<void> _refreshFromFirestore() async {
    final freshTask = await ref.read(firebaseServiceProvider).getTaskById(widget.task.taskId);
    if (!mounted || freshTask == null) return; // Guards against disposal or missing documents

    setState(() {
      _taskName = freshTask.title; // Updates the title
      _selectedDate = DateTime(freshTask.startDate.year, freshTask.startDate.month, freshTask.startDate.day); // Updates the date
      _startTime = TimeOfDay.fromDateTime(freshTask.startDate); // Updates the start time
      _endTime = TimeOfDay.fromDateTime(freshTask.endDate); // Updates the end time
      _selectedPriority = _priorityLabel(freshTask.priority); // Converts the number to a label
      _selectedTag = freshTask.tagName ?? noTagOption; // Falls back to the default option
    });
  }

  // Converts a TimeOfDay object into a human-readable string (e.g. "10:30 AM")
  // Uses manual formatting instead of the intl plugin
  String _formatTime(TimeOfDay time) {
    // Converts 24-hour format to 12-hour format
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    // Pads the minute value with a leading zero if needed (e.g. 5 becomes "05")
    final minute = time.minute.toString().padLeft(2, '0');
    // Determines whether the time is AM or PM
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period'; // Outputs format like "10:30 AM"
  }

  // Formats the selected task date for the date field.
  String _formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy').format(date);
  }

  // Converts a priority number into the label shown in the selector.
  String _priorityLabel(int priority) {
    if (priority == 1) return 'Low';
    if (priority == 3) return 'High';
    return 'Medium';
  }

  // Converts the selected priority label back into a Firestore number.
  int _priorityValue(String priority) {
    if (priority == 'Low') return 1;
    if (priority == 'High') return 3;
    return 2;
  }

  // Combines the selected task date with a selected time.
  DateTime _createDateTime(TimeOfDay time) {
    return DateTime(
      _selectedDate.year, // Uses the selected year
      _selectedDate.month, // Uses the selected month
      _selectedDate.day, // Uses the selected day
      time.hour, // Uses the selected hour
      time.minute, // Uses the selected minute
    );
  }

  // Opens the built-in Material date picker.
  Future<void> _pickDate() async {
    // Closes the keyboard before displaying the date picker.
    FocusScope.of(context).unfocus();

    // Uses the current date when the saved task is not already in the past.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Removes the time before comparing the saved task date with today.
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    // Keeps past tasks editable without allowing earlier past dates.
    final firstDate = selectedDay.isBefore(today) ? selectedDay : today;

    // Sets the usual maximum date for newly selected future dates.
    final maximumDate = DateTime(today.year + 5, 12, 31);

    // Keeps unusually far-future tasks editable without a picker error.
    final lastDate = selectedDay.isAfter(maximumDate)
        ? selectedDay
        : maximumDate;

    // Opens the date picker using the current selected task date.
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDay,
      firstDate: firstDate, // Prevents a task from moving earlier into the past
      lastDate: lastDate, // Allows future dates while keeping saved dates valid
      builder: (context, child) {
        // Applies the colours used by the app's other pickers.
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme(
              brightness: Brightness.dark, // Keeps the picker in dark mode
              primary: highlightColour, // Colours the selected time and buttons
              onPrimary: textPrimaryColour, // Text on the selected time
              secondary: highlightColour, // Secondary accent
              onSecondary: textPrimaryColour, // Text on secondary
              surface: darkGreyColour, // Picker dialog background
              onSurface: textPrimaryColour, // Time values text
              error: Colors.redAccent, // Validation error colour
              onError: textPrimaryColour, // Text on error
            ),
            // Styles the "Select time" header text
            timePickerTheme: TimePickerThemeData(
              helpTextStyle: TextStyle(
                color: textSecondaryColour, // Uses the theme's secondary text colour
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    // Keeps the existing date when the picker is cancelled.
    if (pickedDate == null || !mounted) return;

    // Saves the newly selected task date.
    setState(() => _selectedDate = pickedDate);
  }

  // Displays the built-in Material time picker and updates the corresponding state variable
  Future<void> _pickTime({required bool isStart}) async {
    // Launches the Material Design time picker dialog
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? _startTime
          : _endTime, // Uses the current value as the initial selection
      builder: (context, child) {
        // Wraps the picker in a theme to match the app's UI
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme(
              brightness: Brightness.dark, // Keeps the picker in dark mode
              primary: highlightColour, // Colours the selected time and buttons
              onPrimary: textPrimaryColour, // Text on the selected time
              secondary: highlightColour, // Secondary accent
              onSecondary: textPrimaryColour, // Text on secondary
              surface: darkGreyColour, // Picker dialog background
              onSurface: textPrimaryColour, // Time values text
              error: Colors.redAccent, // Validation error colour
              onError: textPrimaryColour, // Text on error
            ),
            // Styles the "Select time" header text
            timePickerTheme: TimePickerThemeData(
              helpTextStyle: TextStyle(
                color: textSecondaryColour, // Uses the theme's secondary text colour
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          child: child!, // The actual time picker widget
        );
      },
    );

    // Stops when the picker is cancelled or the modal is no longer visible.
    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        _startTime = picked; // Updates the start time state
      } else {
        _endTime = picked; // Updates the end time state
      }
    });

    // Updates the matching form field after a new time is selected.
    if (isStart) {
      // Saves the selected start time in its form field.
      _startTimeFieldKey.currentState?.didChange(picked);

      // Rechecks the end-time error because the comparison uses the start time.
      _endTimeFieldKey.currentState?.validate();
    } else {
      // Saves the selected end time and refreshes its validation message.
      _endTimeFieldKey.currentState?.didChange(picked);

      // Clears or displays the range error immediately after the end time changes.
      _endTimeFieldKey.currentState?.validate();
    }
  }

  // Performs full form validation, then updates the Firestore task.
  Future<void> _handleSaveChanges() async {
    // Triggers all form field validators before proceeding
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save(); // Triggers the form field onSaved callbacks

    // Converts both selected times into minutes for comparison.
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    // Stops the save when the selected end time is not after the start time.
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      // Updates the UI state to show the loading spinner on the Save button
      setState(() => _isSaving = true);

      // Gets the service that updates task documents in Firestore.
      final firebaseService = ref.read(firebaseServiceProvider);

      // Saves the latest task values to the matching Firestore document.
      await firebaseService.updateTask(
        taskId: widget.task.taskId,
        title: _taskName, // Uses the saved task name
        startDate: _createDateTime(_startTime),
        endDate: _createDateTime(_endTime),
        priority: _priorityValue(_selectedPriority),
        tagName: _selectedTag == noTagOption ? null : _selectedTag,
      );

      // Cancels the old notification and schedules a new one for the updated time.
      // Wrapped in try/catch so the task saves even if notifications are unavailable.
      try {
        final notification = ref.read(notificationProvider);
        notification.cancelNotification(widget.task.taskId.hashCode);
        notification.scheduleTaskNotification(
          id: widget.task.taskId.hashCode, // Uses the same document ID hash for consistent cancellation
          title: _taskName, // Uses the updated task name as the notification title
          startDate: _createDateTime(_startTime), // Fires the notification at the updated start time
        );
      } catch (_) {
        // Continues without updating the notification when scheduling fails.
      }

      // Prevents the app from crashing if the user dismisses the modal before the request finishes
      if (!mounted) return;

      // Captures the messenger before the modal's context is deactivated.
      final messenger = ScaffoldMessenger.of(context);

      // Closes the bottom sheet modal after successful update
      Navigator.pop(context, true); // Reports the successful task update

      // Displays a success notification at the bottom of the screen
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Task updated successfully!',
            style: TextStyle(color: textPrimaryColour),
          ),
          backgroundColor:
              Colors.green, // Green background for success feedback
          behavior: SnackBarBehavior.floating, // Floating pill style matching the app's existing SnackBar pattern
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ), // Matches the corner radius used across the application
          margin: const EdgeInsets.only(
            bottom: 20, // Pushes the SnackBar up from the bottom of the screen
            left: 24, // Side padding to align with the screen content layout
            right: 24,
          ),
        ),
      );
    } catch (e) {
      // Prevents the app from crashing if the user dismisses the modal before the error is handled
      if (!mounted) return;

      // Displays an error notification if the task update fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update task: $e',
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor:
              Colors.redAccent, // Red background for error feedback
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
        ),
      );
    } finally {
      // Resets the loading state regardless of success or failure
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Shows a confirmation dialog, then deletes the task if confirmed
  // Uses AlertDialog for confirmation before performing the destructive action
  Future<void> _handleDeleteTask() async {
    // --- DELETE CONFIRMATION DIALOG ---
    // Shows a Material AlertDialog asking the user to confirm the deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            darkGreyColour, // Dark background matching the app theme
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            16,
          ), // Rounded corners matching the app's card design
        ),
        // Dialog title with a warning icon
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 24,
            ), // Red warning icon
            const SizedBox(
              width: 8,
            ), // Horizontal spacing between the icon and title text
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
            onPressed: () => Navigator.pop(
              context,
              false,
            ), // Returns false to indicate cancellation
            child: Text(
              'Cancel',
              style: TextStyle(
                color: accentColour,
              ), // Accent text for the cancel action
            ),
          ),
          // Confirm delete button — returns true to proceed with deletion
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              true,
            ), // Returns true to confirm deletion
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ), // Red text to indicate destructive action
            ),
          ),
        ],
      ),
    );

    // If the user cancelled the dialog (or dismissed it), stop here
    if (confirmed != true) return;

    try {
      // Updates the UI state to show the loading spinner on the Delete button
      setState(() => _isDeleting = true);

      // Gets the service that deletes task documents from Firestore.
      final firebaseService = ref.read(firebaseServiceProvider);

      // Deletes the selected task after the user confirms the action.
      await firebaseService.deleteTask(widget.task.taskId);

      // Cancels the notification for the deleted task.
      // Wrapped in try/catch so the delete completes even if cancellation fails.
      try {
        await ref.read(notificationProvider).cancelNotification(widget.task.taskId.hashCode);
      } catch (_) {
        // Continues with the deletion when notification cancellation fails.
      }

      // Prevents the app from crashing if the user dismisses the modal before the request finishes
      if (!mounted) return;

      // Captures the messenger before the modal's context is deactivated.
      final messenger = ScaffoldMessenger.of(context);

      // Closes the bottom sheet modal after successful deletion
      Navigator.pop(context, true); // Reports the successful task deletion

      // Displays a success notification confirming the task was deleted
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Task deleted.',
            style: TextStyle(color: textPrimaryColour),
          ),
          backgroundColor: Colors
              .redAccent, // Red background to reinforce the deletion context
          behavior: SnackBarBehavior.floating, // Floating pill style
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete task: $e',
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // Builds one option inside the priority selector used by Create Task.
  Widget _buildPriorityButton(String label) {
    final isSelected =
        _selectedPriority ==
        label; // Highlights the saved or newly selected priority

    return Expanded(
      child: GestureDetector(
        // Prevents the priority from changing while Firestore is saving or deleting.
        onTap: (_isSaving || _isDeleting)
            ? null
            : () => setState(() => _selectedPriority = label),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 150,
          ), // Keeps the selection change smooth
          margin: const EdgeInsets.all(
            3,
          ), // Leaves a small gap around the selected option
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? accentColour : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? blackColour : accentColour,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider); // Rebuilds when the colour scheme changes
    
    // Uses the same flat dark bottom sheet as the Create Task modal.
    return Container(
      decoration: BoxDecoration(
        color: darkGreyColour,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Adds consistent internal padding around all form elements
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      // Makes the modal content scrollable if the keyboard pushes the content upwards
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize
              .min, // Shrinks the column to fit its children tightly
          crossAxisAlignment: CrossAxisAlignment
              .start, // Left-aligns all child widgets by default
          children: [
            // --- DRAG HANDLE ---
            // Visual indicator that this is a draggable bottom sheet
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(
                  bottom: 16,
                ), // Space below the handle before the title
                decoration: BoxDecoration(
                  color: textSecondaryColour.withValues(alpha: 0.3,), // Semi-transparent white handle
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // --- TITLE ROW ---
            // Arranges the "Edit Task" title and the close button at opposite ends
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Task',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColour,
                  ),
                ),
                // Close button to dismiss the modal without saving
                GestureDetector(
                  // Keeps the form open until the current Firestore request finishes.
                  onTap: (_isSaving || _isDeleting)
                      ? null
                      : () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    color: textSecondaryColour.withValues(alpha: 0.7),
                    size: 24,
                  ),
                ),
              ],
            ),

            // Vertical spacing before the form fields
            const SizedBox(height: 24),

            // --- FORM WRAPPER ---
            // Groups all input fields and enables batch validation via _formKey
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- TASK NAME FIELD ---
                  Text(
                    'Task Name',
                    style: TextStyle(
                      color: accentColour,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Task name text input field pre-populated with the existing title
                  TextFormField(
                    initialValue: _taskName, // Displays the current task name
                    style: TextStyle(color: textPrimaryColour),
                    decoration: InputDecoration(
                      hintText: 'e.g. Advanced Calculus Worksheet',
                      hintStyle: TextStyle(
                        color: labelColour.withValues(alpha: 0.4),
                      ),
                      prefixIcon: Icon(
                        Icons.edit_note,
                        color: textSecondaryColour,
                      ),
                      filled: true,
                      fillColor: blackColour,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a task name';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      // Saves the task name after validation succeeds
                      _taskName = value!; // Stores the edited task name
                    },
                  ),

                  const SizedBox(height: 20),

                  // --- TASK DATE FIELD ---
                  Text(
                    'Task Date',
                    style: TextStyle(
                      color: accentColour,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Opens the date picker when the saved date is tapped.
                  GestureDetector(
                    // Stops another picker from opening while a task request is active.
                    onTap: (_isSaving || _isDeleting) ? null : _pickDate,
                    child: Container(
                      width: double
                          .infinity, // Makes the date field fill the modal width
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: blackColour,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            color: textSecondaryColour,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatDate(
                                _selectedDate,
                              ), // Displays the selected task date
                              overflow: TextOverflow
                                  .ellipsis, // Prevents long dates from overflowing
                              style: TextStyle(
                                color: textPrimaryColour,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: textSecondaryColour,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- TIME FIELDS ROW ---
                  // Arranges the Start Time and End Time fields side by side
                  Row(
                    children: [
                      // --- START TIME FIELD ---
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Time',
                              style: TextStyle(
                                color: accentColour,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Validates the start time inside the form.
                            FormField<TimeOfDay>(
                              key:
                                  _startTimeFieldKey, // Connects the field to the form
                              validator: (_) {
                                // Keeps the field valid because an existing task always has a start time.
                                return null;
                              },
                              builder: (field) {
                                return GestureDetector(
                                  // Stops the start time changing during a task request.
                                  onTap: (_isSaving || _isDeleting)
                                      ? null
                                      : () => _pickTime(isStart: true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: blackColour,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          color: textSecondaryColour,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        // Displays the saved or newly selected start time.
                                        Text(
                                          _formatTime(_startTime),
                                          style: TextStyle(
                                            color: textPrimaryColour,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // --- END TIME FIELD ---
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End Time',
                              style: TextStyle(
                                color: accentColour,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Validates the end time against the selected start time.
                            FormField<TimeOfDay>(
                              key:
                                  _endTimeFieldKey, // Connects the field to the form
                              validator: (_) {
                                // Converts both selected times into minutes for comparison.
                                final startMinutes =
                                    _startTime.hour * 60 + _startTime.minute;
                                final endMinutes =
                                    _endTime.hour * 60 + _endTime.minute;

                                // Prevents an end time before or equal to the start time.
                                if (endMinutes <= startMinutes) {
                                  return 'End time must be after start time';
                                }

                                // Clears the inline error when the time range is valid.
                                return null;
                              },
                              builder: (field) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      // Stops the end time changing during a task request.
                                      onTap: (_isSaving || _isDeleting)
                                          ? null
                                          : () => _pickTime(isStart: false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: blackColour,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              color: textSecondaryColour,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            // Displays the pre-selected end time.
                                            Text(
                                              _formatTime(_endTime),
                                              style: TextStyle(
                                                color: textPrimaryColour,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Shows the same inline validation feedback as Create Task.
                                    if (field.hasError)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 6,
                                          left: 12,
                                        ),
                                        child: Text(
                                          field.errorText!,
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // --- TAG DROPDOWN FIELD ---
                  Text(
                    'Tag',
                    style: TextStyle(
                      color: accentColour, // Sets the accent label colour
                      fontSize: 14, // Sets the label size
                      fontWeight: FontWeight.w600, // Makes the label stand out
                    ),
                  ),
                  const SizedBox(height: 8), // Adds space below the tag label

                  // Arranges the tag dropdown and the add tag button horizontally.
                  Row(
                    children: [
                      // Forces the dropdown to fill the remaining width.
                      Expanded(
                        // Watches the user's Firestore tag list.
                        child: ref.watch(tagsProvider).when(
                          // Builds the dropdown after the tags have loaded.
                          data: (tagList) {
                            // Keeps the AI-generated tag visible when the task was created by the AI.
                            final effectiveTags = [...tagList]; // Creates a copy of the Firestore tags
                            if (widget.task.tagName == 'Generated' && !effectiveTags.contains('Generated')) {
                              effectiveTags.add('Generated'); // Preserves the AI tag for existing generated tasks
                            }

                            // Resets the selected tag when it no longer exists in Firestore.
                            final validTags = [noTagOption, ...effectiveTags]; // Combines the default option with the user's tags
                            if (!validTags.contains(_selectedTag)) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) setState(() => _selectedTag = noTagOption); // Resets to the default option
                              });
                            }

                            return DropdownButtonFormField<String>(
                              initialValue: _selectedTag, // Displays the currently selected tag
                              dropdownColor: blackColour, // Uses a dark dropdown menu
                              style: TextStyle(color: textPrimaryColour, fontSize: 14), // Sets the dropdown text style
                              icon: Icon(
                                Icons.keyboard_arrow_down, // Sets the dropdown arrow icon
                                color: textSecondaryColour, // Sets the arrow colour
                              ),
                              decoration: InputDecoration(
                                hintText: 'Select a tag', // Displays the tag placeholder
                                hintStyle: TextStyle(
                                  color: labelColour, // Sets the placeholder colour
                                ),
                                filled: true, // Enables the input background colour
                                fillColor: blackColour, // Sets the black background colour
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12), // Rounds the input corners
                                  borderSide: BorderSide.none, // Removes the default border line
                                ),
                              ),
                              // Creates one dropdown option for each tag.
                              items: validTags.map((tag) {
                                return DropdownMenuItem<String>(
                                  value: tag, // Sets the tag value
                                  child: Text(tag), // Displays the tag name
                                );
                              }).toList(),
                              onChanged: (value) {
                                // Saves the selected tag option for task creation.
                                if (value != null) {
                                  setState(() => _selectedTag = value); // Updates the selected tag
                                }
                              },
                            );
                          },

                          // Shows a loading indicator while tags are being fetched.
                          loading: () => Container(
                            height: 56, // Matches the dropdown height
                            decoration: BoxDecoration(
                              color: blackColour, // Matches the dropdown background
                              borderRadius: BorderRadius.circular(12), // Rounds the field corners
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 20, // Sets the spinner width
                                height: 20, // Sets the spinner height
                                child: CircularProgressIndicator(
                                  color: accentColour, // Uses the accent colour
                                  strokeWidth: 2, // Keeps the spinner compact
                                ),
                              ),
                            ),
                          ),

                          // Falls back to a dropdown with only the default option on error.
                          error: (_, _) => DropdownButtonFormField<String>(
                            initialValue: noTagOption, // Selects the default option
                            dropdownColor: blackColour, // Uses a dark dropdown menu
                            style: TextStyle(color: textPrimaryColour, fontSize: 14), // Sets the text style
                            decoration: InputDecoration(
                              filled: true, // Enables the input background colour
                              fillColor: blackColour, // Sets the black background colour
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12), // Rounds the input corners
                                borderSide: BorderSide.none, // Removes the default border line
                              ),
                            ),
                            items: [
                              DropdownMenuItem<String>(
                                value: noTagOption, // Sets the default value
                                child: Text(noTagOption), // Displays the default label
                              ),
                            ],
                            onChanged: (_) {}, // Prevents interaction during the error state
                          ),
                        ),
                      ),

                      const SizedBox(width: 10), // Adds space between the dropdown and the add button

                      // Opens a dialog to create a new tag.
                      GestureDetector(
                        onTap: () async {
                          // Opens the shared tag management dialog.
                          final deletedTag = await showManageTagsDialog(
                            context: context, // Supplies the current screen context
                            ref: ref, // Passes the Riverpod reference
                            currentSelectedTag: _selectedTag, // Tracks the active dropdown selection
                          );

                          // Resets the dropdown when the selected tag was deleted.
                          if (deletedTag != null && mounted) {
                            setState(() => _selectedTag = noTagOption); // Clears the selection
                          }
                        },
                        child: Container(
                          width: 48, // Sets the button width
                          height: 48, // Sets the button height
                          decoration: BoxDecoration(
                            color: blackColour, // Matches the dropdown background
                            borderRadius: BorderRadius.circular(12), // Rounds the button corners
                            border: Border.all(
                              color: accentColour.withValues(alpha: 0.3), // Adds a subtle accent border
                            ),
                          ),
                          child: Icon(
                            Icons.add, // Displays the add icon
                            color: accentColour, // Uses the accent colour
                            size: 22, // Sets the icon size
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // --- PRIORITY SELECTOR ---
                  Text(
                    'Priority',
                    style: TextStyle(
                      color: accentColour,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Uses the same single-container selector as Create Task.
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: blackColour,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildPriorityButton('Low'),
                        _buildPriorityButton('Medium'),
                        _buildPriorityButton('High'),
                      ],
                    ),
                  ),

                  // Vertical spacing before the action buttons
                  const SizedBox(height: 28),

                  // --- SAVE CHANGES BUTTON ---
                  // Primary action button to save the edited task data
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColour,
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    // Disables the button while saving or deleting to prevent conflicts
                    onPressed: (_isSaving || _isDeleting)
                        ? null
                        : _handleSaveChanges,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Color.fromARGB(221, 0, 0, 0),
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons
                                    .check_box, // Checkmark box icon for the save action
                                color: Color.fromARGB(221, 0, 0, 0),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Color.fromARGB(221, 0, 0, 0),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),

                  // Vertical spacing between the two buttons
                  const SizedBox(height: 12),

                  // --- DELETE TASK BUTTON ---
                  // Destructive action button styled in red to indicate danger
                  // Triggers an AlertDialog confirmation before proceeding
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors
                          .redAccent, // Red background to signal a destructive action
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    // Disables the button while saving or deleting to prevent conflicts
                    onPressed: (_isSaving || _isDeleting)
                        ? null
                        : _handleDeleteTask,
                    child: _isDeleting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors
                                  .white, // White spinner on the red button
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons
                                    .delete_outline, // Trash icon for the delete action
                                color: textPrimaryColour,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Delete Task',
                                style: TextStyle(
                                  color: textPrimaryColour,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
