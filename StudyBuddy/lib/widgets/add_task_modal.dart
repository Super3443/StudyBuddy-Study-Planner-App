import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:mbap_project/providers/notification_provider.dart';
import 'package:mbap_project/providers/tags_provider.dart';
import 'package:mbap_project/providers/theme_provider.dart'; // Application theme colours and styling
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Connects the modal to Riverpod
import 'package:mbap_project/providers/firebase_provider.dart'; // Provides access to FirebaseService
import 'package:intl/intl.dart'; // Formats the selected task date
import 'package:mbap_project/widgets/manage_tags_dialog.dart'; // Shared tag management dialog and noTagOption constant

// The modal's widget, immutable, points to its state class below
class CreateTaskModal extends ConsumerStatefulWidget {
  const CreateTaskModal({super.key});

  @override
  ConsumerState<CreateTaskModal> createState() => _CreateTaskModalState();
}

// Holds the mutable state and UI logic for the Create Task modal form
class _CreateTaskModalState extends ConsumerState<CreateTaskModal> {
  final _formKey = GlobalKey<FormState>(); // Global key to identify and validate the form
  String _taskName = ''; // Stores the validated task name

  // Identifies the custom start time field inside the form.
  final _startTimeFieldKey = GlobalKey<FormFieldState<TimeOfDay>>(); // Validates the start time field

  // Identifies the custom end time field inside the form.
  final _endTimeFieldKey = GlobalKey<FormFieldState<TimeOfDay>>(); // Validates the end time field

  // Stores the date selected for the new task.
  DateTime _selectedDate = DateTime.now(); // Defaults new tasks to today

  TimeOfDay? _startTime; // Selected start time
  TimeOfDay? _endTime; // Selected end time

  // Starts with no tag selected instead of a subject tag.
  String _selectedTag = noTagOption; // Defaults to the optional tag choice
  int _selectedPriority = 2; // Defaults to Medium priority
  bool _isCreating = false; // Tracks loading state during submission

  // Formats the selected date into an readable value.
  String _formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy').format(date);
  }

  // Manually formats TimeOfDay to a 12-hour string (e.g. "11:30 PM")
  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
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

    // Gets today without its current time for the earliest allowed date.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Opens the date picker using the currently selected task date.
    final pickedDate = await showDatePicker(
      context: context, // Uses the modal's current screen context
      initialDate: _selectedDate, // Opens on the currently selected date
      firstDate: today, // Prevents new tasks from being created in the past
      lastDate: DateTime(
        today.year + 5,
        12,
        31,
      ), // Allows tasks up to five years ahead
      builder: (context, child) {
        // Applies the same dark colours used by the time picker.
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

    // Saves the newly selected task date and refreshes the field.
    setState(() {
      _selectedDate = pickedDate;
    });
  }

  // Opens the built-in Material time picker
  Future<void> _pickTime({required bool isStart}) async {
    // Opens on the saved time or the current time when none was chosen.
    final picked = await showTimePicker(
      context: context, // Uses the modal's current screen context
      initialTime: isStart
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now()),
      builder: (context, child) {
        // Wraps the picker in a custom dark theme
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

    // Stops if no time was selected or the modal was closed
    if (picked == null || !mounted) return;

    // Saves the chosen value in the correct time field.
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });

    // Updates the inline validation message for the changed time.
    if (isStart) {
      // Saves the selected start time in its form field.
      _startTimeFieldKey.currentState?.didChange(picked);

      // Rechecks the end time when one has already been selected.
      if (_endTime != null) {
        // Updates the end-time error when Start Time changes.
        _endTimeFieldKey.currentState?.validate();
      }
    } else {
      // Saves the selected end time in its form field.
      _endTimeFieldKey.currentState?.didChange(picked);
    }
  }

  // Validates the form and triggers the creation process
  Future<void> _handleCreateTask() async {
    // Stops execution if standard form fields are invalid
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save(); // Triggers the form field onSaved callbacks

    try {
      // Shows the loading spinner
      setState(() => _isCreating = true);

      // Gets the service that writes task data to Firestore.
      final firebaseService = ref.read(firebaseServiceProvider);

      // Combines the selected date with the chosen start time.
      final startDate = _createDateTime(_startTime!);

      // Combines the same selected date with the chosen end time.
      final endDate = _createDateTime(_endTime!);

      /// Saves the new task in the tasks collection and captures its document ID.
      final taskId = await firebaseService.createTask(
        title: _taskName, // Uses the saved task name
        startDate: startDate, // Saves the selected starting date and time
        endDate: endDate, // Saves the selected ending date and time
        priority: _selectedPriority, // Saves the chosen priority number
        // Converts the visible no-tag option into a Firestore null value.
        tagName: _selectedTag == noTagOption ? null : _selectedTag,
      );

      // Schedules a local notification using the Firestore document ID.
      // Wrapped in try/catch so the task saves even if notifications are unavailable.
      try {
        final notification = ref.read(notificationProvider);
        notification.scheduleTaskNotification(
          id: taskId.hashCode, // Uses the document ID hash for consistent cancellation
          title: _taskName, // Uses the task name as the notification title
          startDate: startDate, // Fires the notification at the task's start time
        );
      } catch (_) {
        // Continues without a notification when scheduling fails.
      }

      if (!mounted) return;

      // Captures the messenger before the modal's context is deactivated.
      final messenger = ScaffoldMessenger.of(context);

      // Closes the modal on success
      Navigator.pop(context);

      // Shows success notification
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Task created successfully!',
            style: TextStyle(color: textPrimaryColour),
          ),
          backgroundColor: Colors.green, // Uses green for successful creation
          behavior: SnackBarBehavior.floating, // Floats the message above the screen
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ), // Rounds the message corners
          margin: const EdgeInsets.only(
            bottom: 20,
            left: 24,
            right: 24,
          ), // Adds space around the message
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Captures the messenger before the modal's context is deactivated.
      final messenger = ScaffoldMessenger.of(context);

      // Shows error notification
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create task: $e',
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.redAccent, // Uses red for a failed creation
          behavior: SnackBarBehavior.floating, // Floats the message above the screen
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ), // Rounds the message corners
          margin: const EdgeInsets.only(
            bottom: 20,
            left: 24,
            right: 24,
          ), // Adds space around the message
        ),
      );
    } finally {
      // Hides the loading spinner
      if (mounted) setState(() => _isCreating = false);
    }
  }

  // Builds one button in the priority selector.
  Widget _buildPriorityButton(String label, int value) {
    final isSelected =
        _selectedPriority == value; // Checks whether this priority is active

    return Expanded(
      child: GestureDetector(
        // Saves this priority when its section is tapped.
        onTap: () {
          setState(() => _selectedPriority = value);
        },
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 150,
          ), // Smoothly changes the selected colour
          margin: const EdgeInsets.all(
            3,
          ), // Leaves a small gap inside the selector
          alignment: Alignment.center, // Centres the priority label
          decoration: BoxDecoration(
            color: isSelected
                ? accentColour
                : Colors.transparent, // Highlights only the selected priority
            borderRadius: BorderRadius.circular(
              9,
            ), // Rounds the selected background
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
    
    // --- MODAL CONTAINER ---
    return Container(
      decoration: BoxDecoration(
        color: darkGreyColour,
        // Rounds only the top corners
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24,
      ), // Adds space around the modal contents
      // Makes the modal content scrollable to avoid keyboard overlap
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Shrinks vertically to fit contents
          crossAxisAlignment:
              CrossAxisAlignment.start, // Aligns the form contents to the left
          children: [
            // --- DRAG HANDLE ---
            Center(
              child: Container(
                width: 40, // Sets the drag handle width
                height: 4, // Keeps the drag handle thin
                margin: const EdgeInsets.only(
                  bottom: 16,
                ), // Adds space below the drag handle
                decoration: BoxDecoration(
                  color: textSecondaryColour.withValues(
                    alpha: 0.3,
                  ), // Gives the handle a soft white colour
                  borderRadius: BorderRadius.circular(
                    2,
                  ), // Rounds the handle ends
                ),
              ),
            ),

            // --- TITLE ROW ---
            Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceBetween, // Keeps the title and close button apart
              children: [
                Text(
                  'Create Task',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColour,
                  ),
                ),
                // Close button to dismiss the modal
                GestureDetector(
                  onTap: () =>
                      Navigator.pop(context), // Closes the modal when tapped
                  child: Icon(
                    Icons.close,
                    color: textSecondaryColour,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24), // Adds space below the title row
            // --- FORM WRAPPER ---
            Form(
              key: _formKey, // Connects every field to the form validator
              child: Column(
                crossAxisAlignment: CrossAxisAlignment
                    .start, // Aligns each form field to the left
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
                  const SizedBox(
                    height: 8,
                  ), // Adds space below the task name label
                  TextFormField(
                    style: TextStyle(
                      color: textPrimaryColour,
                    ), // Displays entered text in white
                    decoration: InputDecoration(
                      hintText: 'e.g. Advanced Calculus Worksheet',
                      hintStyle: TextStyle(
                        color: labelColour,
                      ),
                      prefixIcon: Icon(
                        Icons.edit_note,
                        color: textPrimaryColour.withValues(alpha: 0.6),
                      ),
                      filled: true, // Fills the text field background
                      fillColor: blackColour, // Uses the black field background
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    // Validates that the task name is not empty
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a task name';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      // Saves the task name after validation succeeds
                      _taskName = value!; // Stores the entered task name
                    },
                  ),

                  const SizedBox(
                    height: 20,
                  ), // Adds space before the task date section
                  // --- TASK DATE FIELD ---
                  Text(
                    'Task Date',
                    style: TextStyle(
                      color: accentColour,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8), // Adds space before the date field
                  // Wraps the date field so it opens the picker when tapped.
                  GestureDetector(
                    // Prevents another picker from opening while the task is being created.
                    onTap: _isCreating ? null : _pickDate,
                    child: Container(
                      width: double
                          .infinity, // Makes the date field fill the modal width
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: blackColour,
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Matches the other form fields
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            color: textPrimaryColour.withValues(
                              alpha: 0.6,
                            ), // Softens the calendar icon colour
                            size: 20, // Keeps the calendar icon compact
                          ),

                          const SizedBox(
                            width: 8,
                          ), // Adds space after the calendar icon
                          // Uses the remaining width for the formatted date.
                          Expanded(
                            child: Text(
                              _formatDate(
                                _selectedDate,
                              ), // Displays the currently selected date
                              overflow: TextOverflow
                                  .ellipsis, // Prevents overflow on narrow screens
                              style: TextStyle(
                                color: textPrimaryColour,
                                fontSize: 14,
                              ),
                            ),
                          ),

                          Icon(
                            Icons.keyboard_arrow_down,
                            color: textPrimaryColour.withValues(
                              alpha: 0.6,
                            ), // Softens the dropdown arrow colour
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ), // Adds space before the time fields
                  // --- TIME FIELDS ROW ---
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
                            const SizedBox(
                              height: 8,
                            ), // Adds space below the start time label
                            // Validates the start time inside the form.
                            FormField<TimeOfDay>(
                              // Connects this FormField to the start time key.
                              key: _startTimeFieldKey,

                              // Checks the current start time when the form submits.
                              validator: (_) {
                                // Shows an error when no start time was selected.
                                if (_startTime == null) {
                                  return 'Please select a start time';
                                }

                                // Rejects a start time that has already passed when the task date is today.
                                final now = DateTime.now();
                                final today = DateTime(now.year, now.month, now.day);
                                final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
                                if (selected == today) {
                                  final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
                                  final nowMinutes = now.hour * 60 + now.minute;
                                  if (startMinutes < nowMinutes) {
                                    return 'Start time has already passed';
                                  }
                                }

                                // Clears the error when a start time is available.
                                return null;
                              },

                              // Builds the custom time box and its error text.
                              builder: (field) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      // Opens the picker for the start time.
                                      onTap: () => _pickTime(isStart: true),
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
                                              color: textPrimaryColour.withValues(
                                                alpha: 0.6,
                                              ),
                                              size: 20,
                                            ),
                                            const SizedBox(
                                              width: 8,
                                            ), // Adds space after the clock icon
                                            Text(
                                              // Shows the picked time or a placeholder.
                                              _startTime != null
                                                  ? _formatTime(_startTime!)
                                                  : '-- : -- --',
                                              style: TextStyle(
                                                color: _startTime != null
                                                    ? textPrimaryColour
                                                    : labelColour,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Displays the validation message below Start Time.
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
                      const SizedBox(
                        width: 16,
                      ), // Separates the start and end time fields
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
                            const SizedBox(
                              height: 8,
                            ), // Adds space below the end time label
                            // Validates the end time inside the form.
                            FormField<TimeOfDay>(
                              // Connects this FormField to the end time key.
                              key: _endTimeFieldKey,

                              // Checks the current end time when the form submits.
                              validator: (_) {
                                // Shows an error when no end time was selected.
                                if (_endTime == null) {
                                  return 'Please select an end time';
                                }

                                // Lets Start Time show its own missing-time error.
                                if (_startTime == null) return null;

                                // Converts both times into minutes for comparison.
                                final startMinutes =
                                    _startTime!.hour * 60 + _startTime!.minute;
                                final endMinutes =
                                    _endTime!.hour * 60 + _endTime!.minute;

                                // Prevents an end time before or equal to Start Time.
                                if (endMinutes <= startMinutes) {
                                  return 'End time must be after start time';
                                }

                                // Clears the error when the end time is valid.
                                return null;
                              },

                              // Builds the custom time box and its error text.
                              builder: (field) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      // Opens the picker for the end time.
                                      onTap: () => _pickTime(isStart: false),
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
                                            const SizedBox(
                                              width: 8,
                                            ), // Adds space after the clock icon
                                            Text(
                                              // Shows the picked time or a placeholder.
                                              _endTime != null
                                                  ? _formatTime(_endTime!)
                                                  : '-- : -- --',
                                              style: TextStyle(
                                                color: _endTime != null
                                                    ? textPrimaryColour
                                                    : labelColour,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Displays the validation message below End Time.
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
                  const SizedBox(height: 20,), // Adds space before the tag section

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
                            // Resets the selected tag when it no longer exists in Firestore.
                            final validTags = [noTagOption, ...tagList]; // Combines the default option with the user's tags
                            if (!validTags.contains(_selectedTag)) {
                              // Schedules the reset after the current build completes.
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
                              color: accentColour.withValues(alpha: 0.7), // Increases the border opacity
                              width: 2, // Thickens the border line
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
                  const SizedBox(
                    height: 20,
                  ), // Adds space before the priority section
                  
                  // --- PRIORITY SELECTOR ---
                  Text(
                    'Priority',
                    style: TextStyle(
                      color: accentColour,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ), // Adds space below the priority label
                  Container(
                    height: 44, // Sets a consistent selector height
                    decoration: BoxDecoration(
                      color: blackColour, // Uses the black selector background
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Rounds the selector corners
                    ),
                    child: Row(
                      children: [
                        _buildPriorityButton('Low', 1),
                        _buildPriorityButton('Medium', 2),
                        _buildPriorityButton('High', 3),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ), 
                  // Adds space before the create button
                  // --- CREATE TASK BUTTON ---
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          accentColour, // Uses the main accent button colour
                      minimumSize: const Size.fromHeight(
                        55,
                      ), // Gives the button a clear tap area
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: _isCreating
                        ? null
                        : _handleCreateTask, // Prevents repeated taps while saving
                    child: _isCreating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Color.fromARGB(221, 0, 0, 0),
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment
                                .center, // Centres the icon and button text
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Color.fromARGB(221, 0, 0, 0),
                                size: 20,
                              ),
                              SizedBox(
                                width: 8,
                              ), // Adds space between the icon and text
                              Text(
                                'Create Task',
                                style: TextStyle(
                                  color: Color.fromARGB(221, 0, 0, 0),
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
