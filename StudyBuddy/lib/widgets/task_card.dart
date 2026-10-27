import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:mbap_project/providers/theme_provider.dart'; // Application theme colours and styling

// A card widget to display task information
class TaskCard extends StatelessWidget {
  final String title; // Title of task card
  final String? category; // Category of task card
  final String date; // Date when the task is scheduled
  final String time; // Time range of task card e.g 9:00 AM - 10:30 AM
  final int priority; // Priority level of the task (High, Medium, Low)
  final bool isCompleted;
  final bool isDeleteMode; // Shows a delete icon instead of the completion checkbox

  /// Optional callback when the edit icon is tapped
  final VoidCallback? onEdit;

  /// Optional callback when the checkbox is tapped
  final VoidCallback? onToggle;

  // Constructor requiring task details and optional action callbacks
  const TaskCard({
    super.key,
    required this.title,
    required this.category,
    required this.date,
    required this.time,
    required this.priority,
    required this.isCompleted,
    this.isDeleteMode = false, // Defaults to normal completion mode
    this.onEdit,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Outer container for the card's background and border
    return Container(
      decoration: BoxDecoration(
        color: darkGreyColour,
        borderRadius: BorderRadius.circular(
          12,
        ), // Rounds the corners of the card
        border: Border.all(
          color: borderColour,
        ), // White border with 5% opacity
      ),
      // Clips the inner children to ensure they do not overflow the rounded corners
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        // Forces the row children to match the height of the tallest element
        child: IntrinsicHeight(
          // Arranges the vertical accent line and the main content horizontally
          child: Row(
            children: [
              // --- VERTICAL ACCENT BORDER ---
              // Accent left indicator border
              Container(width: 4, color: accentColour.withValues(alpha: 0.8)),

              // --- MAIN CARD CONTENT ---
              // Forces the content to fill all remaining horizontal space
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(
                    16.0,
                  ), // Applies 16 pixels of uniform padding inside the card
                  // Arranges the task details, edit button, and checkbox horizontally
                  child: Row(
                    children: [
                      // --- TASK DETAILS (TEXT) ---
                      // Takes up all available space before the buttons
                      Expanded(
                        // Arranges the title, category, date, and time vertically
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // Left-aligns the text
                          children: [
                            // Task title text
                            Text(
                              title,
                              style: TextStyle(
                                color: textPrimaryColour,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            // Vertical spacing between the Title and Category
                            const SizedBox(height: 6),

                            // --- CATEGORY ROW ---
                            // Only displays this row if a category was provided
                            if (category != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons
                                        .local_offer_outlined, // Small tag icon
                                    size: 15,
                                    color: accentColour,
                                  ),
                                  const SizedBox(
                                    width: 6,
                                  ), // Horizontal spacing between Icon and text
                                  // Category label text
                                  Text(
                                    category!,
                                    style: TextStyle(
                                      color: accentColour,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),

                            // Vertical spacing before the task date
                            const SizedBox(height: 4),

                            // --- DATE ROW ---
                            // Displays the date when the task is scheduled
                            Row(
                              children: [
                                Icon(
                                  Icons
                                      .calendar_today_outlined, // Small calendar icon
                                  size: 14,
                                  color: accentColour,
                                ),
                                const SizedBox(
                                  width: 6,
                                ), // Horizontal spacing between icon and text
                                // Scheduled task date text
                                Expanded(
                                  child: Text(
                                    date,
                                    overflow: TextOverflow
                                        .ellipsis, // Prevents long dates from overflowing
                                    style: TextStyle(
                                      color: accentColour,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Vertical spacing between the Date and Time
                            const SizedBox(height: 4),

                            // --- TIME ROW ---
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time, // Small clock icon
                                  size: 14,
                                  color: accentColour,
                                ),
                                const SizedBox(
                                  width: 6,
                                ), // Horizontal spacing between icon and text
                                // Time range text
                                Text(
                                  time,
                                  style: TextStyle(
                                    color: accentColour,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            // Vertical spacing between the Time and Priority
                            const SizedBox(height: 4),

                            // --- PRIORITY ROW ---
                            Row(
                              children: [
                                Icon(
                                  Icons.flag_outlined, // Small flag icon for priority
                                  size: 14,
                                  color: priority == 3
                                      ? Colors.redAccent // Red for high priority
                                      : priority == 2
                                          ? Colors.orangeAccent // Orange for medium priority
                                          : Colors.greenAccent, // Green for low priority
                                ),
                                const SizedBox(width: 6), // Horizontal spacing between icon and text
                                // Priority label text
                                Text(
                                  '${priority == 3 ? 'High' : priority == 2 ? 'Medium' : 'Low'} Priority',
                                  style: TextStyle(
                                    color: priority == 3
                                        ? Colors.redAccent // Red for high priority
                                        : priority == 2
                                            ? Colors.orangeAccent // Orange for medium priority
                                            : Colors.greenAccent, // Green for low priority
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // --- EDIT BUTTON ---
                      // Hides the edit control when the card is display-only.
                      if (onEdit != null)
                        GestureDetector(
                          onTap:
                              onEdit, // Runs the supplied edit action when tapped
                          // Arranges the icon and text vertically.
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment
                                .center, // Centres them vertically
                            children: [
                              Icon(
                                Icons.edit, // Displays the edit pencil icon
                                size: 20, // Sets the edit icon size
                                color:
                                    accentColour, // Uses the peach accent colour
                              ),
                              const SizedBox(
                                height: 4,
                              ), // Adds space below the icon
                              Text(
                                'Edit', // Labels the edit action
                                style: TextStyle(
                                  color:
                                      accentColour, // Uses the peach text colour
                                  fontSize:
                                      10, // Keeps the action label compact
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Adds spacing only when both action controls are visible.
                      if (onEdit != null && onToggle != null)
                        const SizedBox(
                          width: 16,
                        ), // Separates both action controls
                      // --- COMPLETION CHECKBOX ---
                      // Hides the completion control when the card is display-only.
                      if (onToggle != null)
                        GestureDetector(
                          onTap:
                              onToggle, // Runs the supplied completion action
                          child: Icon(
                            // Shows the red X icon in delete mode, or the completion circle in normal mode
                            isDeleteMode
                                ? Icons.cancel_outlined // X icon for deleting tasks
                                : isCompleted
                                    ? Icons.check_circle // Filled circle for completed tasks
                                    : Icons.radio_button_unchecked, // Empty circle for incomplete tasks
                            color: isDeleteMode
                                ? Colors.redAccent // Red colour for the delete icon
                                : isCompleted
                                    ? highlightColour // Green colour for completed tasks
                                    : unselectedNavColour, // Dimmed colour for incomplete tasks
                            size: 28, // Sets the icon size
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
