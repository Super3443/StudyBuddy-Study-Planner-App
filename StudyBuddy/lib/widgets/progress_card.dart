import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:mbap_project/providers/theme_provider.dart'; // Application theme colours and styling

// Custom widget that displays a dashboard card summarising daily progress
class ProgressCard extends StatelessWidget {
  // Value of progress rounded up based on tasksDone e.g '4/6 = 66.666% = 67%'
  final double progress;
  
  // e.g. '3h 30m'
  final String studyTime;

  // e.g. '4/6'
  final String tasksDone;

  // Constructor requiring the progress, planned time and task-count values.
  const ProgressCard({
    super.key,
    required this.progress,
    required this.studyTime,
    required this.tasksDone,
  });

  @override
  Widget build(BuildContext context) {
    // Converts the decimal progress into a whole number percentage string
    final percentLabel = '${(progress * 100).round()}%';

    // Outer container providing the card's background and border
    return Container(
      // Internal padding on all sides
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkGreyColour,
        borderRadius: BorderRadius.circular(16), // Rounds the corners of the card
        border: Border.all(color: borderColour), // White outline with 5% opacity
        // Applies a diagonal gradient background from top right to bottom left
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color.lerp(darkGreyColour, accentColour, 0.2)!, // Mixes 5% accent into the base colour
            darkGreyColour, // Card background from the active mode
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Aligns card contents to the left edge
        children: [
          // --- SECTION TITLE ---
          Text(
            "TODAY'S PROGRESS",
            style: TextStyle(
              color: textSecondaryColour.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.5, // Widens the space between letters
            ),
          ),

          // Vertical spacing before the Progress Metrics Section
          const SizedBox(height: 20),

          // --- PROGRESS METRICS ---
          // Arranges the circular chart and statistics side-by-side
          Row(
            children: [
              // --- CIRCULAR PROGRESS RING ---
              // Fixed size box to constrain the circular indicator
              SizedBox(
                width: 100,
                height: 100,
                // Stacks the text precisely in the centre of the progress ring
                child: Stack(
                  fit: StackFit.expand, // Forces children to stretch and fill the 100x100 box
                  children: [
                    // The actual progress ring graphic
                    CircularProgressIndicator(
                      value: progress, // Fills the ring based on the decimal value
                      backgroundColor: textSecondaryColour.withValues(alpha: 0.2), // Track behind the progress
                      color: highlightColour, // Active progress colour
                      strokeWidth: 8, // Thickness of the ring
                      strokeCap: StrokeCap.round, // Rounds the ends of the progress line
                    ),

                    // Centres the percentage text inside the ring
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            percentLabel,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textPrimaryColour.withValues(alpha: 0.9),
                            ),
                          ),
                          Text(
                            'DONE',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight(1000),
                              color: accentColour.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Horizontal spacing between the ring and the side stats
              const SizedBox(width: 38),

              // --- SIDE STATISTICS ---
              // Forces the side stats to fill the remaining horizontal space
              Expanded(
                child: Column(
                  children: [
                    // Shows the total time scheduled for today's tasks.
                    StatPill(
                      icon: Icons.timer_outlined,
                      value: studyTime,
                      label: 'Planned Time',
                    ),
                    const SizedBox(height: 12), // Vertical spacing between the pills
                    // Custom stat pill for completed task count
                    StatPill(
                      icon: Icons.check_circle_outline,
                      value: tasksDone,
                      label: 'Tasks Done',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// A reusable small container displaying an icon, a value, and a label
class StatPill extends StatelessWidget {
  final IconData icon; // The specific Material Icon to display
  final String value; // The primary statistic value (e.g., '3h 30m')
  final String label; // The descriptive label below the value (e.g., 'Study Time')
  
  // The descriptive label below the value (e.g., 'Study Time')
  const StatPill({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });
 
  @override
  Widget build(BuildContext context) {
    // Outer container for the pill background
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Internal padding (16 horizontal, 12 vertical)
      decoration: BoxDecoration(
        color: blackColour.withValues(alpha: 0.7), // Semi-transparent black background
        borderRadius: BorderRadius.circular(12), // Rounds the corners of the stat pill
      ),
      // Arranges the icon and the text column side-by-side
      child: Row(
        children: [
          Icon(icon, color: accentColour),
          const SizedBox(width: 12), // Horizontal spacing between the icon and text
          // Arranges the value and label vertically
          Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Left-aligns the text
            children: [
              Text(
                value,
                style: TextStyle(
                  color: textPrimaryColour,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: accentColour,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
