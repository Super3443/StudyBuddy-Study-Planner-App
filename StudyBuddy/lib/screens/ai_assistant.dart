import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:flutter_riverpod/flutter_riverpod.dart'; // State management library
import 'package:intl/intl.dart'; // Formats generated task dates
import 'package:mbap_project/models/exam_priority.dart';
import 'package:mbap_project/models/generated_task.dart';
import 'package:mbap_project/providers/ai_schedule_provider.dart';
import 'package:mbap_project/providers/ai_access_provider.dart';
import 'package:mbap_project/screens/ai_plan_selection.dart'; // Opens the plan selection screen
import 'package:mbap_project/screens/settings.dart';
import 'package:mbap_project/widgets/exam_card.dart';
import 'package:mbap_project/providers/theme_provider.dart';
import 'package:mbap_project/providers/notification_provider.dart'; // Schedules task notifications

// The screen's widget, immutable, points to its state class below
class AIScreen extends ConsumerStatefulWidget {
  // Opens the Schedule tab after saving a plan
  final VoidCallback onOpenSchedule;

  const AIScreen({super.key, required this.onOpenSchedule});

  @override
  ConsumerState<AIScreen> createState() => _AIScreenState();
}

// Holds the mutable state and UI logic of the AI Assistant screen
class _AIScreenState extends ConsumerState<AIScreen> {
  // Stores the exams entered on this screen until schedule generation starts.
  final List<ExamPriority> _exams = [];

  // Controls whether the exam form or generated plan is displayed.
  bool _isShowingPlan = false;

  // Prevents another save while the Firestore batch is running.
  bool _isSavingPlan = false;

  // Requests a temporary schedule after checking that an exam was entered.
  Future<void> _generateSchedule() async {
    // Shows a dialog when there is no exam information to send.
    if (_exams.isEmpty) {
      showDialog(
        context: context, // Supplies the current screen context
        builder: (dialogContext) => AlertDialog(
          backgroundColor: darkGreyColour, // Sets the dark grey background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Rounds the dialog corners
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded, // Displays the warning icon
                color: Colors.redAccent, // Sets the red warning colour
                size: 24, // Sets the icon size
              ),
              const SizedBox(width: 8), // Adds space before the title
              Text(
                'No Exams Added', // Sets the dialog title
                style: TextStyle(
                  color: textPrimaryColour, // Sets the white text colour
                  fontSize: 18, // Sets the title size
                  fontWeight: FontWeight.bold, // Makes the title bold
                ),
              ),
            ],
          ),
          content: Text(
            'Add at least one exam before generating a schedule.', // Displays the validation message
            style: TextStyle(
              color: textSecondaryColour, // Sets the muted text colour
              fontSize: 14, // Sets the message size
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), // Closes the dialog
              child: Text(
                'OK', // Sets the confirm label
                style: TextStyle(
                  color: accentColour, // Sets the accent colour
                  fontWeight: FontWeight.bold, // Makes the label bold
                ),
              ),
            ),
          ],
        ),
      );
      return; // Stops the generation flow
    }

    // Reads the current free and Pro access details from Riverpod.
    final accessState = ref.read(aiAccessProvider);

    // Stops while the account access check is still loading.
    if (accessState.status == 'idle' || accessState.status == 'loading') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checking your AI access. Please wait.')),
      );
      return;
    }

    // Reloads the access details when the earlier Firestore check failed.
    if (accessState.status == 'error') {
      await ref.read(aiAccessProvider.notifier).loadAccess();

      // Stops if the screen was removed while Firestore was loading.
      if (!mounted) return;

      // Shows a safe message when access still cannot be confirmed.
      if (ref.read(aiAccessProvider).status != 'ready') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to check your AI access. Please try again.'),
          ),
        );
        return;
      }
    }

    // Opens the plan selection when the daily generation limit has been reached.
    if (!ref.read(aiAccessProvider).canGenerateSchedule) {
      await Navigator.pushNamed(
        context,
        AiPlanSelectionScreen.routeName,
      );

      // Stops if the AI screen was removed while plan selection was open.
      if (!mounted) return;

      // Reloads the access state to pick up any newly purchased tier.
      await ref.read(aiAccessProvider.notifier).loadAccess();

      // Stops if the screen was removed during the reload.
      if (!mounted) return;

      // Stops when the purchase did not enable further generations.
      if (!ref.read(aiAccessProvider).canGenerateSchedule) return;
    }

    // Closes the keyboard before the loading state appears.
    FocusManager.instance.primaryFocus?.unfocus();

    // Sends a fixed copy so later list changes cannot alter this request.
    await ref
        .read(aiScheduleProvider.notifier)
        .generateSchedule(List<ExamPriority>.unmodifiable(_exams));

    // Stops if the AI screen was removed while Groq was responding.
    if (!mounted) return;

    // Reads the completed provider result after generation finishes.
    final generatedTasks = ref.read(aiScheduleProvider).value;

    // Opens the plan preview only when valid generated tasks were returned.
    if (generatedTasks != null && generatedTasks.isNotEmpty) {
      setState(
        () => _isShowingPlan = true,
      ); // Replaces the exam form with the preview
    }
  }

  // Clears the temporary generated schedule from Riverpod state.
  void _discardSchedule() {
    ref.read(aiScheduleProvider.notifier).discardSchedule();
    setState(() => _isShowingPlan = false); // Returns to the exam priority form
  }

  // Displays a confirmation dialog for a generated plan action
  Future<bool> _showPlanConfirmation({
    required String title, // Stores the dialog title
    required String message, // Stores the dialog message
    required String cancelLabel, // Stores the cancel button label
    required String confirmLabel, // Stores the confirm button label
    required IconData icon, // Stores the title icon
    required Color confirmColour, // Stores the confirm button colour
  }) async {
    // Waits for the selected dialog action
    final confirmed = await showDialog<bool>(
      context: context, // Supplies the current screen context
      builder: (dialogContext) => AlertDialog(
        // Creates the confirmation dialog
        backgroundColor: darkGreyColour, // Sets the dark grey colour
        shape: RoundedRectangleBorder(
          // Sets the dialog shape
          borderRadius: BorderRadius.circular(16), // Rounds the dialog corners
        ),
        title: Row(
          // Arranges the icon and title horizontally
          children: [
            Icon(
              // Displays the action icon
              icon, // Sets the selected icon
              color: confirmColour, // Sets the icon colour
              size: 24, // Sets the icon size
            ),
            const SizedBox(width: 8), // Adds space before the title
            Expanded(
              // Uses the remaining title width
              child: Text(
                // Displays the dialog title
                title, // Sets the dialog title
                style: TextStyle(
                  // Styles the dialog title
                  color: textPrimaryColour, // Sets the white colour
                  fontSize: 18, // Sets the title size
                  fontWeight: FontWeight.bold, // Makes the title bold
                ),
              ),
            ),
          ],
        ),
        content: Text(
          // Displays the confirmation message
          message, // Sets the confirmation message
          style: TextStyle(
            // Styles the confirmation message
            color: textSecondaryColour, // Sets the faded white colour
            fontSize: 14, // Sets the message size
          ),
        ),
        actions: [
          TextButton(
            // Creates the cancel button
            onPressed: () => Navigator.pop(
              // Closes the confirmation dialog
              dialogContext, // Uses the dialog context
              false, // Returns the cancelled result
            ),
            child: Text(
              // Displays the cancel label
              cancelLabel, // Sets the cancel button label
              style: TextStyle(
                // Styles the cancel label
                color: accentColour, // Sets the accent colour
              ),
            ),
          ),
          TextButton(
            // Creates the confirm button
            onPressed: () => Navigator.pop(
              // Closes the confirmation dialog
              dialogContext, // Uses the dialog context
              true, // Returns the confirmed result
            ),
            child: Text(
              // Displays the confirm label
              confirmLabel, // Sets the confirm button label
              style: TextStyle(
                // Styles the confirm label
                color: confirmColour, // Sets the selected action colour
                fontWeight: FontWeight.bold, // Makes the label bold
              ),
            ),
          ),
        ],
      ),
    );

    // Returns false when the dialog is dismissed
    return confirmed ?? false;
  }

  // Confirms before deleting the generated plan
  Future<void> _confirmDiscardSchedule() async {
    // Displays the discard confirmation
    final confirmed = await _showPlanConfirmation(
      title: 'Discard Generated Plan?', // Sets the dialog title
      message:
          'Going back will delete the generated results. You will need to generate another plan.', // Explains the result
      cancelLabel: 'Stay', // Sets the cancel label
      confirmLabel: 'Discard', // Sets the confirm label
      icon: Icons.warning_amber_rounded, // Sets the warning icon
      confirmColour: Colors.redAccent, // Sets the red colour
    );

    // Stops when the action is cancelled or the screen closes
    if (!confirmed || !mounted) return;

    // Deletes the temporary generated plan
    _discardSchedule();
  }

  // Confirms before replacing the generated plan
  Future<void> _confirmRegenerateSchedule() async {
    // Displays the regeneration confirmation
    final confirmed = await _showPlanConfirmation(
      title: 'Generate Another Plan?', // Sets the dialog title
      message:
          'Regenerating will replace the current generated results.', // Explains the result
      cancelLabel: 'Keep Current', // Sets the cancel label
      confirmLabel: 'Regenerate', // Sets the confirm label
      icon: Icons.refresh, // Sets the refresh icon
      confirmColour: accentColour, // Sets the accent colour
    );

    // Stops when the action is cancelled or the screen closes
    if (!confirmed || !mounted) return;

    // Generates a replacement schedule
    await _generateSchedule();
  }

  // Confirms before saving the generated plan
  Future<void> _confirmAcceptSchedule() async {
    // Displays the save confirmation
    final confirmed = await _showPlanConfirmation(
      title: 'Save Generated Plan?', // Sets the dialog title
      message:
          'The generated tasks will be added to your schedule.', // Explains the result
      cancelLabel: 'Review Plan', // Sets the cancel label
      confirmLabel: 'Save Plan', // Sets the confirm label
      icon: Icons.check_circle_outline, // Sets the confirmation icon
      confirmColour: accentColour, // Sets the accent colour
    );

    // Stops when the action is cancelled or the screen closes
    if (!confirmed || !mounted) return;

    // Saves the confirmed generated plan
    await _acceptSchedule();
  }

  // Saves the accepted schedule and opens the Schedule tab afterwards.
  Future<void> _acceptSchedule() async {
    // Stops repeated taps while the Firestore batch is still running.
    if (_isSavingPlan) return;

    setState(
      () => _isSavingPlan = true,
    ); // Replaces the button label with loading feedback

    // Stores the root messenger before the active tab changes.
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Saves every preview task and receives paired document IDs for notifications.
      final savedTasks = await ref.read(aiScheduleProvider.notifier).saveSchedule();

      // Schedules a notification for each saved generated task.
      // Wrapped in try/catch so the save completes even if notifications are unavailable.
      try {
        final notification = ref.read(notificationProvider);
        for (final entry in savedTasks.entries) {
          notification.scheduleTaskNotification(
            id: entry.key.hashCode,
            title: entry.value.title,
            startDate: entry.value.startDate,
          ); // Fires in the background without blocking the save flow
        }
      } catch (_) {
        // Continues without notifications when scheduling fails.
      }

      // Stops if the AI screen was removed while Firestore was saving.
      if (!mounted) return;

      // Clears the entered exams because their generated plan is now saved.
      setState(() {
        _exams.clear(); // Removes the completed exam priority inputs
        _isShowingPlan = false; // Resets the screen for the next plan
      });

      // Confirms that the complete generated plan was saved successfully.
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'AI generated plan saved successfully!',
            style: TextStyle(
              color: textPrimaryColour,
            ), // Uses white text on the success colour
          ),
          backgroundColor: Colors.green, // Uses green for a successful save
          behavior: SnackBarBehavior
              .floating, // Floats above the bottom navigation bar
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              12,
            ), // Rounds the snackbar corners
          ),
          margin: const EdgeInsets.only(
            bottom: 20, // Leaves space above the navigation area
            left: 24, // Aligns the message with the screen content
            right: 24, // Keeps equal spacing on both sides
          ),
        ),
      );

      // Opens the Schedule tab so the newly saved tasks are visible.
      widget.onOpenSchedule();
    } catch (error) {
      // Stops if the AI screen was removed before the error was returned.
      if (!mounted) return;

      // Displays the save error without leaving the generated preview.
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save the generated plan: $error',
            style: const TextStyle(
              color: Colors.black,
            ), // Uses dark text on the error colour
          ),
          backgroundColor: Colors.redAccent, // Uses red for a failed save
          behavior: SnackBarBehavior
              .floating, // Floats above the bottom navigation bar
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              12,
            ), // Rounds the snackbar corners
          ),
          margin: const EdgeInsets.only(
            bottom: 20, // Leaves space above the navigation area
            left: 24, // Aligns the message with the screen content
            right: 24, // Keeps equal spacing on both sides
          ),
        ),
      );
    } finally {
      // Restores the save button when this screen is still visible.
      if (mounted) setState(() => _isSavingPlan = false);
    }
  }

  // Opens the form used to add one upcoming exam.
  Future<void> _showAddExamModal() async {
    // Waits for the modal to return a completed exam entry.
    final exam = await showModalBottomSheet<ExamPriority>(
      context: context,
      isScrollControlled: true,
      backgroundColor: darkGreyColour,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _AddExamModal(),
    );

    // Stops if the modal was cancelled or the screen was closed.
    if (exam == null || !mounted) return;

    // Waits until the overlay has finished handling the modal result.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Stops if the AI screen was closed before the next frame.
      if (!mounted) return;

      // Adds the returned exam after the overlay update has completed.
      setState(() => _exams.add(exam)); // Adds the completed exam entry

      // Clears an older preview because its exam inputs are now outdated.
      ref.read(aiScheduleProvider.notifier).discardSchedule();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider); // Rebuilds when the colour scheme changes
    
    // Watches the current loading, error or generated schedule state.
    final scheduleState = ref.watch(aiScheduleProvider);

    // Reads the generated task list when the request has completed.
    final generatedTasks = scheduleState.value ?? [];

    // Tracks whether the Groq request is still being processed.
    final isGenerating = scheduleState.isLoading;

    // Displays the separate view after successful generation.
    if (_isShowingPlan || generatedTasks.isNotEmpty) {
      return _buildGeneratedPlan(
        scheduleState: scheduleState, // Supplies loading and error information
        generatedTasks: generatedTasks, // Supplies the temporary preview tasks
        isGenerating: isGenerating, // Controls regeneration loading feedback
      );
    }

    // Prevents UI elements from overlapping with device status bars
    return SafeArea(
      child: Stack(
        // Stacks widgets on top of each other
        children: [
          // --- BACKGROUND GLOW LAYER ---
          // Forces the container to stretch and fill the entire available screen space
          Positioned.fill(
            // Ensures the background glow doesn't accidentally block user taps from reaching the buttons
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  // Creates a circular fading gradient for an ambient glow effect
                  gradient: RadialGradient(
                    center: Alignment(
                      0.0,
                      0.6,
                    ), // Shifts the centre of the glow slightly downwards
                    radius: 0.9, // Increases the size of the glow
                    colors: [
                      highlightColour.withValues(
                        alpha: 0.10,
                      ), // Accent colour at the centre with 10% opacity
                      Colors
                          .transparent, // Fades out to completely transparent at the edges
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- FOREGROUND UI LAYER ---
          // Everything inside here sits on top of the background glow
          Column(
            // Arranges the screen sections vertically
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
              // Wraps the divider in a row to stretch it across the screen
              Row(
                children: [
                  Expanded(
                    child: Divider(color: dividerColour),
                  ),
                ],
              ),

              // --- MAIN INPUT EXAM PRIORITIES SECTION ---
              // Forces the scrollable area to fill all remaining vertical space
              Expanded(
                child: SingleChildScrollView(
                  // Allows the user to scroll vertically if the list of exams gets too long
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    8,
                    24,
                    8,
                  ), // 24 pixels on left/right, 16 on the top/bottom
                  child: Column(
                    // Vertial layout for contents inside
                    crossAxisAlignment: CrossAxisAlignment
                        .center, // Centres all child widgets horizontally within the column
                    children: [
                      // --- TITLE & DESCRIPTION ---
                      Text(
                        'Exam Priorities',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: textPrimaryColour,
                        ),
                      ),

                      // Vertical spacing before the subtitle
                      const SizedBox(height: 8),

                      // Subtitle text explaining the screen's purpose
                      Text(
                        'Rank your upcoming exams to let the AI generate your optimal study schedule.',
                        textAlign: TextAlign
                            .center, // Centres the text alignment if it spans multiple lines
                        style: TextStyle(color: accentColour, fontSize: 18),
                      ),

                      // Vertical spacing before the exam cards
                      const SizedBox(height: 24),

                      // --- EXAM PRIORITY CARDS ---
                      // Loops through the exam list, tracking both the position (index) and the exam data
                      ..._exams.asMap().entries.map((entry) {
                        final index =
                            entry.key; // The list position (0, 1, 2...)
                        final exam =
                            entry.value; // The actual ExamPriority object
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 16,
                          ), // Space below each individual card
                          // Loads the custom card widget, passing the data and functions it needs
                          child: ExamPriorityCard(
                            name: exam.name,
                            examDate: exam.examDate,
                            difficulty: exam.difficulty.toDouble(),
                            // Callback function to remove this specific exam from the list
                            onDelete: () {
                              setState(
                                () => _exams.removeAt(index),
                              ); // Removes this exam entry
                              ref
                                  .read(aiScheduleProvider.notifier)
                                  .discardSchedule(); // Clears the outdated preview
                            },
                            // Callback function to update the difficulty score when the slider moves
                            onDifficultyChanged: (value) {
                              setState(() {
                                _exams[index] = exam.copyWith(
                                  difficulty: value
                                      .round(), // Stores the rounded slider value
                                );
                              });
                              ref
                                  .read(aiScheduleProvider.notifier)
                                  .discardSchedule(); // Clears the outdated preview
                            },
                          ),
                        );
                      }),

                      // --- ADD NEW EXAM BUTTON ---
                      // Dark container providing a background for the outlined button
                      Container(
                        decoration: BoxDecoration(
                          color: darkGreyColour.withValues(alpha: 0.5), // Semi-transparent dark grey background
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: borderColour,
                            width: 3, // Thicker outer border
                          ), // White outline with 10% opacity
                        ),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(75), // Forces the button to stretch across the full width and be 75 pixels tall
                            side: BorderSide(
                              color: accentColour.withValues(alpha: 0.25),
                              width: 2, // Thicker accent border
                            ), // Accent border with 25% opacity around the button itself
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), // Matches the corner radius of the background container
                            ),
                          ),
                          onPressed: isGenerating
                              ? null
                              : _showAddExamModal, // Disables input while generating
                          // Arranges the icon and text horizontally in the exact centre of the button
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                color: accentColour,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Add New Exam',
                                style: TextStyle(
                                  color: accentColour,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1, // Slight extra space between letters
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Vertical spacing before the final button
                      const SizedBox(height: 24),

                      // --- GENERATE OPTIMAL SCHEDULE BUTTON ---
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColour,
                          minimumSize: const Size.fromHeight(
                            70,
                          ), // Forces the button to be 70 pixels tall and full width
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              30,
                            ), // Highly rounded corners for a primary call-to-action button
                          ),
                          elevation:
                              4, // Adds a slight drop shadow behind the button
                        ),
                        onPressed: isGenerating
                            ? null
                            : _generateSchedule, // Starts generation when ready
                        // Displays a spinner while waiting or the normal button content.
                        child: isGenerating
                            ? SizedBox(
                                width: 24, // Sets the loading spinner width
                                height: 24, // Sets the loading spinner height
                                child: CircularProgressIndicator(
                                  color:
                                      deepAccentColour, // Uses the dark button contrast colour
                                  strokeWidth:
                                      2.5, // Keeps the loading ring compact
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .center, // Centres the content horizontally
                                children: [
                                  Icon(
                                    Icons
                                        .auto_awesome, // Displays the AI sparkle icon
                                    color:
                                        deepAccentColour, // Uses the dark button icon colour
                                    size: 22, // Sets the sparkle icon size
                                  ),
                                  SizedBox(
                                    width: 12,
                                  ), // Adds space before the label
                                  Text(
                                    generatedTasks.isEmpty
                                        ? 'Generate Optimal Schedule' // Labels the first request
                                        : 'Generate Another Schedule', // Labels another request
                                    style: TextStyle(
                                      color:
                                          deepAccentColour, // Uses readable dark text
                                      fontSize:
                                          18, // Sets the button label size
                                      fontWeight: FontWeight
                                          .w600, // Makes the label stand out
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      // Displays the request error below the generate button.
                      if (scheduleState.hasError) ...[
                        const SizedBox(
                          height: 20,
                        ), // Adds space before the error card
                        Container(
                          width: double
                              .infinity, // Stretches the error card across the screen
                          padding: const EdgeInsets.all(
                            16,
                          ), // Adds space inside the error card
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(
                              alpha: 0.12,
                            ), // Adds a faint red background
                            borderRadius: BorderRadius.circular(
                              12,
                            ), // Rounds the error card corners
                            border: Border.all(
                              color: Colors.red.withValues(
                                alpha: 0.35,
                              ), // Adds a visible red outline
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment
                                .start, // Aligns the icon with the first line
                            children: [
                              const Icon(
                                Icons
                                    .error_outline, // Displays the error indicator
                                color: Colors
                                    .redAccent, // Uses red for the error icon
                                size: 22, // Sets the error icon size
                              ),
                              const SizedBox(
                                width: 12,
                              ), // Adds space before the message
                              Expanded(
                                child: Text(
                                  scheduleState.error
                                      .toString(), // Displays the readable failure reason
                                  style: const TextStyle(
                                    color: Colors
                                        .white, // Keeps the message readable
                                    fontSize: 14, // Sets the error message size
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Extra space at bottom to prevent content from being hidden by the floating action button
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Builds the generated plan preview
  Widget _buildGeneratedPlan({
    required AsyncValue<List<GeneratedTask>>
    scheduleState, // Stores the current provider result
    required List<GeneratedTask>
    generatedTasks, // Stores the tasks displayed in the preview
    required bool isGenerating, // Stores the generation loading status
  }) {
    // Groups generated tasks by their scheduled date
    final tasksByDate = _groupTasksByDate(generatedTasks);

    // Prevents content from overlapping the status bar
    return SafeArea(
      child: Stack(
        // Stacks the background and content
        children: [
          // --- BACKGROUND GLOW LAYER ---
          Positioned.fill(
            // Fills the available screen space
            child: IgnorePointer(
              // Allows taps to pass through the glow
              child: Container(
                // Holds the background glow
                decoration: BoxDecoration(
                  // Sets the background decoration
                  gradient: RadialGradient(
                    // Creates the circular glow
                    center: const Alignment(
                      0.0, // Keeps the glow centred horizontally
                      0.75, // Moves the glow towards the bottom
                    ),
                    radius: 0.9, // Sets the glow radius
                    colors: [
                      // Sets the gradient colours
                      highlightColour.withValues(
                        alpha: 0.10,
                      ), // Adds a faint accent centre
                      Colors.transparent, // Fades the glow into the background
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- GENERATED PLAN CONTENT ---
          Column(
            // Arranges the generated plan vertically
            children: [
              // Displays the back button and application title
              SizedBox(
                width:
                    double.infinity, // Stretches the header across the screen
                height: 68, // Sets the header height
                child: Stack(
                  // Places the back button over the header
                  alignment: Alignment.center, // Centres the application title
                  children: [
                    Text(
                      'StudyBuddy', // Displays the application title
                      style: TextStyle(
                        color: textPrimaryColour, // Uses white header text
                        fontSize: 26, // Sets the header title size
                        fontWeight:
                            FontWeight.bold, // Makes the title prominent
                      ),
                    ),
                    Positioned(
                      // Positions the back button
                      left: 8, // Places the back button near the left edge
                      child: IconButton(
                        // Creates the back button
                        onPressed: _isSavingPlan
                            ? null
                            : _confirmDiscardSchedule, // Confirms before returning
                        icon: Icon(
                          // Sets the back button icon
                          Icons.arrow_back, // Displays the back arrow
                          color: accentColour, // Uses the accent accent colour
                          size: 24, // Sets the back arrow size
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Separates the header from the generated plan
              Divider(
                height: 1, // Keeps the divider thin
                color: dividerColour, // Uses a subtle white line
              ),

              // Allows longer generated plans to scroll
              Expanded(
                child: SingleChildScrollView(
                  // Enables vertical scrolling
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    28,
                    20,
                    44,
                  ), // Adds space around the plan
                  child: Column(
                    // Arranges the plan contents vertically
                    crossAxisAlignment: CrossAxisAlignment
                        .start, // Aligns plan content to the left
                    children: [
                      // --- PLAN TITLE ---
                      Row(
                        // Arranges the icon and title horizontally
                        children: [
                          Container(
                            // Holds the sparkle icon
                            width: 40, // Sets the sparkle background width
                            height: 40, // Sets the sparkle background height
                            decoration: BoxDecoration(
                              // Styles the icon background
                              color: const Color(0xFF4B455C), // Sets the purple-grey colour
                              borderRadius: BorderRadius.circular(8), // Rounds the icon background
                            ),
                            child: const Icon(
                              // Displays the sparkle icon
                              Icons.auto_awesome, // Displays the AI sparkle icon
                              color: Color(
                                0xFFD5C8FF,
                              ), // Uses a light purple icon colour
                              size: 24, // Sets the sparkle icon size
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ), // Adds space before the plan title
                          Expanded(
                            // Uses the remaining title space
                            child: Text(
                              // Displays the plan title
                              'AI Generated Plan', // Labels the generated schedule
                              style: TextStyle(
                                color: textPrimaryColour, // Uses white title text
                                fontSize: 34,
                                fontWeight: FontWeight.bold, // Makes the heading prominent
                                letterSpacing: -1.1, // Keeps the wide title on one line
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 28,
                      ), // Adds space before the schedule sections
                      // Shows a loading indicator during generation
                      if (isGenerating && generatedTasks.isEmpty)
                        Padding(
                          // Adds space around the loading indicator
                          padding: EdgeInsets.symmetric(
                            vertical: 80,
                          ), // Adds space around loading
                          child: Center(
                            // Centres the loading indicator
                            child: CircularProgressIndicator(
                              // Displays the loading spinner
                              color: accentColour, // Uses the main accent colour
                            ),
                          ),
                        ),

                      // Displays the generation error
                      if (scheduleState.hasError) ...[
                        Container(
                          // Holds the error message
                          width: double.infinity, // Stretches the error across the preview
                          padding: const EdgeInsets.all(16,), // Adds space around the error message
                          decoration: BoxDecoration(
                            // Styles the error message
                            color: Colors.red.withValues(alpha: 0.12,), // Uses a faint red background
                            borderRadius: BorderRadius.circular(12,), // Rounds the error container
                            border: Border.all(
                              // Adds the error border
                              color: Colors.red.withValues(
                                alpha: 0.35,
                              ), // Adds a red outline
                            ),
                          ),
                          child: Text(
                            // Displays the error text
                            scheduleState.error
                                .toString(), // Displays the generation failure reason
                            style: TextStyle(
                              color: textPrimaryColour, // Keeps the message readable
                              fontSize: 14, // Sets the error message size
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ), // Adds space before the previous plan
                      ],

                      // Builds one section for each generated date
                      ...tasksByDate.entries.map((entry) {
                        return _buildDateSection(
                          date: entry.key, // Supplies the section date
                          tasks: entry
                              .value, // Supplies tasks planned for that date
                        );
                      }),
                      // Adds space before the save button
                      const SizedBox(height: 20),

                      // --- ACCEPT AND SAVE BUTTON ---
                      ElevatedButton(
                        // Creates the save plan button
                        onPressed:
                            isGenerating ||
                                _isSavingPlan ||
                                generatedTasks.isEmpty
                            ? null
                            : _confirmAcceptSchedule, // Confirms before saving the plan
                        style: ElevatedButton.styleFrom(
                          // Styles the save plan button
                          backgroundColor:
                              accentColour, // Uses the accent action colour
                          disabledBackgroundColor: accentColour.withValues(alpha: 0.45), // Dims unavailable saving
                          minimumSize: const Size.fromHeight(74), // Sets the save button height
                          elevation: 0, // Keeps the button surface flat
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              // Rounds the button corners
                              38,
                            ), // Creates the pill shape
                          ),
                        ),
                        child:
                            _isSavingPlan // Changes the content while saving
                            ? SizedBox(
                                width: 24, // Sets the save spinner width
                                height: 24, // Sets the save spinner height
                                child: CircularProgressIndicator(
                                  // Displays the save spinner
                                  color: deepAccentColour, // Uses the dark contrast colour
                                  strokeWidth: 2.5, // Keeps the spinner compact
                                ),
                              )
                            : Row(
                                // Arranges the save icon and text
                                mainAxisAlignment: MainAxisAlignment
                                    .center, // Centres the icon and text
                                children: [
                                  Icon(
                                    // Displays the save icon
                                    Icons.check_circle_outline, // Displays the confirmation icon
                                    color: deepAccentColour, // Uses the dark contrast colour
                                    size: 20, // Sets the confirmation icon size
                                  ),
                                  SizedBox(
                                    width: 9,
                                  ), // Adds space before the button label
                                  Text(
                                    // Displays the save button label
                                    'Accept & Save Plan', // Labels the save action
                                    style: TextStyle(
                                      color: deepAccentColour, // Uses readable dark text
                                      fontSize: 17, // Sets the save label size
                                      fontWeight: FontWeight.w600, // Makes the label clear
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      // Adds space between both action buttons
                      const SizedBox(height: 16),
                      // --- REGENERATE BUTTON ---
                      OutlinedButton(
                        // Creates the regenerate button
                        onPressed: isGenerating || _isSavingPlan
                            ? null
                            : _confirmRegenerateSchedule, // Confirms before regenerating
                        style: OutlinedButton.styleFrom(
                          // Styles the regenerate button
                          backgroundColor: const Color(
                            0xFF2A2624, // Sets the dark brown colour
                          ), // Uses the dark brown surface
                          disabledBackgroundColor: const Color(
                            0xFF2A2624, // Sets the disabled brown colour
                          ), // Keeps the shape while loading
                          minimumSize: const Size.fromHeight(
                            74,
                          ), // Sets the regenerate button height
                          side: BorderSide(
                            // Sets the button outline
                            color: accentColour.withValues(
                              alpha: 0.3,
                            ), // Adds a subtle accent outline
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              // Rounds the button corners
                              38,
                            ), // Creates the pill shape
                          ),
                        ),
                        child:
                            isGenerating // Changes the content during generation
                            ? const SizedBox(
                                width:
                                    24, // Sets the regeneration spinner width
                                height:
                                    24, // Sets the regeneration spinner height
                                child: CircularProgressIndicator(
                                  // Displays the loading spinner
                                  color: Colors
                                      .white, // Uses white loading feedback
                                  strokeWidth: 2.5, // Keeps the spinner compact
                                ),
                              )
                            : Row(
                                // Arranges the refresh icon and text
                                mainAxisAlignment: MainAxisAlignment
                                    .center, // Centres the icon and text
                                children: [
                                  Icon(
                                    // Displays the refresh icon
                                    Icons.refresh, // Displays the regenerate icon
                                    color: Colors.white, // Matches the button label colour
                                    size: 21, // Sets the regenerate icon size
                                  ),
                                  SizedBox(
                                    width: 9,
                                  ), // Adds space before the label
                                  Text(
                                    // Displays the regenerate label
                                    'Regenerate Schedule',
                                    style: TextStyle(
                                      color: Colors.white, // Uses white button text
                                      fontSize: 17, // Sets the regenerate label size
                                      fontWeight: FontWeight.w500, // Keeps the label readable
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Groups the generated tasks by their calendar date
  Map<DateTime, List<GeneratedTask>> _groupTasksByDate(
    List<GeneratedTask>
    generatedTasks, // Stores the complete generated schedule
  ) {
    // Keeps each date in the order it appears
    final tasksByDate = <DateTime, List<GeneratedTask>>{};

    // Adds every task to its matching date
    for (final task in generatedTasks) {
      // Removes the time from the date key
      final taskDate = DateTime(
        task.startDate.year, // Uses the task year
        task.startDate.month, // Uses the task month
        task.startDate.day, // Uses the task day
      );

      // Creates the date list and adds the task
      tasksByDate.putIfAbsent(taskDate, () => <GeneratedTask>[]).add(task);
    }

    return tasksByDate; // Returns every ordered date section
  }

  // Builds one date section with its generated tasks
  Widget _buildDateSection({
    required DateTime date, // Stores the section date
    required List<GeneratedTask> tasks, // Stores the tasks for this date
  }) {
    // Reads the current local date
    final now = DateTime.now();

    // Removes the current time before comparing dates
    final today = DateTime(now.year, now.month, now.day);

    // Calculates the number of days from today
    final daysFromToday = date.difference(today).inDays;

    // Selects the heading for the scheduled date
    final sectionTitle = switch (daysFromToday) {
      0 => "Today's Schedule", // Labels tasks scheduled for today
      1 => "Tomorrow's Schedule", // Labels tasks scheduled for tomorrow
      _ => DateFormat(
        'EEEE, d MMMM',
      ).format(date), // Labels later schedule dates
    };

    // Displays the date heading and its tasks
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start, // Aligns the section to the left
      children: [
        Row(
          // Arranges the heading and date horizontally
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Separates title and date
          children: [
            Expanded(
              // Uses the remaining heading space
              child: Text(
                // Displays the schedule heading
                sectionTitle, // Displays the friendly schedule heading
                style: TextStyle(
                  color: textPrimaryColour, // Uses white section text
                  fontSize: 20, // Sets the section heading size
                  fontWeight: FontWeight.w600, // Makes the heading stand out
                ),
              ),
            ),
            const SizedBox(width: 12), // Adds space before the date label
            Text(
              // Displays the section date
              DateFormat(
                'MMM d, yyyy',
              ).format(date), // Displays the full section date
              style: TextStyle(
                color: accentColour.withValues(
                  alpha: 0.9,
                ), // Uses a soft accent date colour
                fontSize: 13, // Keeps the date label compact
              ),
            ),
          ],
        ),

        // Adds space before the first task card
        const SizedBox(height: 18),

        // Converts each generated task into a task card
        ...tasks.map((task) {
          return Padding(
            // Adds spacing around the task card
            padding: const EdgeInsets.only(
              bottom: 16,
            ), // Adds space below each plan card
            child: _GeneratedPlanTaskCard(
              // Displays one generated task
              task: task, // Supplies the generated task
            ), // Displays one generated task
          );
        }),

        // Separates this date from the next section
        const SizedBox(height: 10),
      ],
    );
  }
}

// Displays one generated task card
class _GeneratedPlanTaskCard extends StatelessWidget {
  final GeneratedTask task; // Stores the task displayed by this card

  const _GeneratedPlanTaskCard({required this.task}); // Creates the task card

  @override
  Widget build(BuildContext context) {
    // Formats the start and end times
    final startTime = TimeOfDay.fromDateTime(task.startDate).format(context);
    final endTime = TimeOfDay.fromDateTime(task.endDate).format(context);

    // Displays the generated task information
    return Container(
      width: double.infinity, // Stretches the card across the available width
      constraints: const BoxConstraints(
        minHeight: 70, // Sets the minimum card height
      ), // Keeps every card easy to read
      decoration: BoxDecoration(
        // Styles the task card
        color: darkGreyColour, // Sets the dark grey colour
        borderRadius: BorderRadius.circular(8), // Rounds the card corners
        border: Border.all(
          // Adds the card outline
          color: accentColour.withValues(
            alpha: 0.2,
          ), // Adds a faint accent outline
        ),
      ),
      child: ClipRRect(
        // Clips content to the rounded corners
        borderRadius: BorderRadius.circular(
          8,
        ), // Clips the accent to the card corners
        child: IntrinsicHeight(
          // Matches the accent height to the card
          child: Row(
            // Arranges the accent and details horizontally
            children: [
              Container(
                // Displays the left accent
                width: 5, // Sets the left accent width
                color: accentColour, // Uses the accent accent
              ),
              Expanded(
                // Uses the remaining card width
                child: Padding(
                  // Adds space around the task details
                  padding: const EdgeInsets.symmetric(
                    horizontal:
                        18, // Adds space either side of the task details
                    vertical: 16, // Adds space above and below the task details
                  ),
                  child: Row(
                    // Arranges the times and title horizontally
                    children: [
                      SizedBox(
                        // Sets the width for both task times
                        width: 72, // Keeps all task titles aligned vertically
                        child: Column(
                          // Arranges both times vertically
                          mainAxisSize: MainAxisSize.min, // Uses only the required time height
                          crossAxisAlignment: CrossAxisAlignment.start, // Aligns both times to the left
                          children: [
                            Text(
                              // Displays the starting time
                              startTime, // Displays the generated starting time
                              style: TextStyle(
                                color: textPrimaryColour, // Adapts to light and dark mode
                                fontSize: 15, // Sets the starting time size
                                fontWeight: FontWeight
                                    .w600, // Makes the starting time prominent
                              ),
                            ),
                            const SizedBox(
                              height: 2,
                            ), // Adds a small gap between both times
                            Text(
                              // Displays the ending time
                              endTime, // Displays the generated ending time
                              style: TextStyle(
                                color: accentColour.withValues(
                                  alpha: 0.9,
                                ), // Uses accent ending time text
                                fontSize: 13, // Sets the ending time size
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Adds space before the task title
                      const SizedBox(width: 18),

                      Expanded(
                        // Uses the remaining title space
                        child: Text(
                          // Displays the generated task title
                          task.title, // Displays the generated task title
                          style: TextStyle(
                            color: textPrimaryColour, // Adapts to light and dark mode
                            fontSize: 15, // Sets the starting time size
                            fontWeight: FontWeight
                                .w600, // Makes the starting time prominent
                          ),
                        ),
                      ),
                    ],
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

// Displays the form used to add one exam
class _AddExamModal extends StatefulWidget {
  const _AddExamModal(); // Creates the add exam modal

  @override
  State<_AddExamModal> createState() => _AddExamModalState();
}

// Holds the input values for the add exam modal
class _AddExamModalState extends State<_AddExamModal> {
  final _formKey =
      GlobalKey<FormState>(); // Identifies the exam form for validation
  String _examName = ''; // Stores the validated exam name
  DateTime? _selectedDate; // Stores the chosen exam date
  double _difficulty = 5; // Starts the difficulty slider in the middle
  String? _dateError; // Displays an error when no exam date was selected
  bool _isSubmitting = false; // Prevents the modal from being closed twice

  // Opens the date picker from tomorrow onwards
  Future<void> _pickExamDate() async {
    FocusScope.of(
      context,
    ).unfocus(); // Closes the keyboard before the picker opens
    final now = DateTime.now(); // Reads the current date and time
    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day + 1,
    ); // Creates tomorrow's date

    final pickedDate = await showDatePicker(
      // Opens the exam date picker
      context: context, // Supplies the current screen context
      initialDate:
          _selectedDate ?? tomorrow, // Sets the initially selected date
      firstDate: tomorrow, // Prevents past and current dates
      lastDate: DateTime(
        tomorrow.year + 5,
        12,
        31,
      ), // Sets the final selectable date
      builder: (context, child) {
        // Applies the dark colours to the date picker
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme(
              brightness: Brightness.dark, // Keeps the picker in dark mode
              primary: highlightColour, // Colours the selected date and buttons
              onPrimary: textPrimaryColour, // Text on the selected date
              secondary: highlightColour, // Secondary accent
              onSecondary: textPrimaryColour, // Text on secondary
              surface: darkGreyColour, // Picker dialog background
              onSurface: textPrimaryColour, // Calendar day text
              error: Colors.redAccent, // Validation error colour
              onError: textPrimaryColour, // Text on error
            ),
          ),
          child: child!, // Displays the date picker
        );
      },
    );

    // Stops when the picker was cancelled or the modal was closed.
    if (pickedDate == null || !mounted) return;

    setState(() {
      // Updates the selected exam date
      _selectedDate = pickedDate; // Stores the selected date
      _dateError = null; // Clears the date error
    });
  }

  // Validates the inputs and returns the completed exam to the screen.
  void _addExam() {
    // Ignores another tap while the modal is closing
    if (_isSubmitting) return;

    final hasValidName = _formKey.currentState!
        .validate(); // Checks the exam name

    setState(() {
      // Updates the date validation message
      _dateError = _selectedDate == null
          ? 'Please select an exam date'
          : null; // Sets the date error
    });

    // Keeps the modal open until every required value is valid.
    if (!hasValidName || _selectedDate == null) return;

    _formKey.currentState!.save(); // Triggers the exam name onSaved callback

    final exam = ExamPriority(
      // Creates the completed exam entry
      name: _examName, // Stores the saved exam name
      examDate: _selectedDate!, // Stores the selected exam date
      difficulty: _difficulty.round(), // Stores the whole difficulty value
    );

    setState(() => _isSubmitting = true); // Disables the button before closing
    FocusManager.instance.primaryFocus
        ?.unfocus(); // Removes the text field overlay first

    // Closes the modal after the current overlay update has completed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Stops if the modal was already removed before the next frame.
      if (!mounted) return;

      Navigator.pop(context, exam); // Returns the exam to the AI screen
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Adds space around the modal
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24, // Clears the keyboard
      ),
      child: SingleChildScrollView(
        // Allows the modal to scroll
        child: Form(
          // Groups the validated input fields
          key: _formKey, // Links the form validation key
          child: Column(
            // Arranges the form contents vertically
            mainAxisSize: MainAxisSize.min, // Uses the required modal height
            crossAxisAlignment:
                CrossAxisAlignment.start, // Aligns contents to the left
            children: [
              Text(
                // Displays the modal title
                'Add New Exam', // Sets the modal title
                style: TextStyle(
                  color: textPrimaryColour, // Sets the white colour
                  fontSize: 26, // Sets the title size
                  fontWeight: FontWeight.bold, // Makes the title bold
                ),
              ),
              const SizedBox(height: 24), // Adds space below the title
              Text(
                // Displays the exam name label
                'Exam Name', // Sets the exam name label
                style: TextStyle(
                  color: accentColour, // Sets the accent colour
                  fontSize: 14, // Sets the label size
                  fontWeight: FontWeight.w600, // Makes the label stand out
                ),
              ),
              const SizedBox(height: 8), // Adds space below the label
              TextFormField(
                // Creates the exam name input
                style: TextStyle(
                  color: textPrimaryColour,
                ), // Sets the input text colour
                decoration: InputDecoration(
                  // Styles the exam name input
                  hintText:
                      'e.g. Mathematics', // Displays the example exam name
                  hintStyle: TextStyle(
                    color: labelColour, // Sets the hint colour
                  ),
                  prefixIcon: Icon(
                    // Displays the exam icon
                    Icons.school_outlined, // Sets the exam icon
                    color: textSecondaryColour, // Sets the icon colour
                  ),
                  filled: true, // Enables the input background colour
                  fillColor: blackColour, // Sets the black background colour
                  border: OutlineInputBorder(
                    // Sets the input border
                    borderRadius: BorderRadius.circular(
                      12,
                    ), // Rounds the input corners
                    borderSide:
                        BorderSide.none, // Removes the default border line
                  ),
                ),
                // Checks that an exam name was entered.
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an exam name';
                  }
                  return null;
                },
                onSaved: (value) {
                  // Saves the exam name after validation succeeds
                  _examName = value!
                      .trim(); // Removes spaces around the exam name
                },
              ),
              const SizedBox(height: 20), // Adds space before the date label
              Text(
                // Displays the exam date label
                'Exam Date', // Sets the exam date label
                style: TextStyle(
                  color: accentColour, // Sets the accent colour
                  fontSize: 14, // Sets the label size
                  fontWeight: FontWeight.w600, // Makes the label stand out
                ),
              ),
              const SizedBox(height: 8), // Adds space below the date label
              InkWell(
                // Makes the exam date field tappable
                onTap: _pickExamDate, // Opens the exam date picker
                borderRadius: BorderRadius.circular(
                  12,
                ), // Rounds the tap area corners
                child: Container(
                  // Holds the selected exam date
                  width: double.infinity, // Uses the available modal width
                  padding: EdgeInsets.symmetric(
                    horizontal: 12, // Adds horizontal spacing
                    vertical: 16, // Adds vertical spacing
                  ),
                  decoration: BoxDecoration(
                    // Styles the date field
                    color: blackColour, // Sets the black background colour
                    borderRadius: BorderRadius.circular(
                      12,
                    ), // Rounds the field corners
                  ),
                  child: Row(
                    // Arranges the calendar icon and date
                    children: [
                      Icon(
                        // Displays the calendar icon
                        Icons.calendar_month_outlined, // Sets the calendar icon
                        color: textSecondaryColour, // Sets the icon colour
                      ),
                      const SizedBox(width: 12), // Adds space before the date
                      Text(
                        // Displays the selected date
                        _selectedDate == null
                            ? 'Select exam date' // Displays the date placeholder
                            : MaterialLocalizations.of(
                                context,
                              ).formatMediumDate(
                                _selectedDate!,
                              ), // Formats the selected date
                        style: TextStyle(
                          color: _selectedDate == null
                              ? labelColour // Sets the placeholder colour
                              : textPrimaryColour, // Sets the selected date colour
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_dateError != null)
                Padding(
                  // Adds space around the date error
                  padding: const EdgeInsets.only(
                    left: 12,
                    top: 8,
                  ), // Positions the error text
                  child: Text(
                    // Displays the date error
                    _dateError!, // Sets the date error message
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.error, // Sets the error colour
                      fontSize: 12, // Sets the error text size
                    ),
                  ),
                ),
              const SizedBox(
                height: 20,
              ), // Adds space before the difficulty label
              Row(
                // Arranges the difficulty label and value
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Places them on opposite sides
                children: [
                  Text(
                    // Displays the difficulty label
                    'DIFFICULTY (1-10)', // Sets the difficulty range label
                    style: TextStyle(
                      color: accentColour, // Sets the accent colour
                      fontSize: 12, // Sets the difficulty label size
                      fontWeight: FontWeight.bold, // Makes the label bold
                    ),
                  ),
                  Text(
                    // Displays the selected difficulty
                    _difficulty
                        .round()
                        .toString(), // Converts the difficulty into text
                    style: TextStyle(
                      color: accentColour, // Sets the accent colour
                      fontSize: 16, // Sets the difficulty value size
                      fontWeight: FontWeight.bold, // Makes the value bold
                    ),
                  ),
                ],
              ),
              Slider(
                // Creates the difficulty slider
                value: _difficulty, // Sets the selected difficulty
                min: 1, // Sets the minimum difficulty
                max: 10, // Sets the maximum difficulty
                divisions: 9, // Creates whole number steps
                activeColor: highlightColour, // Sets the accent colour
                inactiveColor: unselectedNavColour, // Sets the inactive colour
                onChanged: (value) {
                  setState(
                    () => _difficulty = value,
                  ); // Updates the selected difficulty
                },
              ),
              const SizedBox(height: 20), // Adds space before the add button
              ElevatedButton(
                // Creates the add exam button
                onPressed: _isSubmitting
                    ? null
                    : _addExam, // Adds the exam when enabled
                style: ElevatedButton.styleFrom(
                  // Styles the add exam button
                  backgroundColor: accentColour, // Sets the accent colour
                  minimumSize: const Size.fromHeight(56), // Sets the button height
                  shape: RoundedRectangleBorder(
                    // Sets the button shape
                    borderRadius: BorderRadius.circular(28), // Rounds the button corners
                  ),
                ),
                child: Text(
                  // Displays the add exam label
                  'Add Exam', // Sets the button label
                  style: TextStyle(
                    color: deepAccentColour, // Sets the dark brown colour
                    fontSize: 17, // Sets the button text size
                    fontWeight: FontWeight.w600, // Makes the label stand out
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
