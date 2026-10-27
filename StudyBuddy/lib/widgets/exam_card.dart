import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:intl/intl.dart' show DateFormat; // Formats the exam date
import 'package:mbap_project/providers/theme_provider.dart'; // Application theme colours

// A card widget that displays an exam's name and difficulty, with a slider to adjust the difficulty and a delete button.
class ExamPriorityCard extends StatelessWidget {
  final String name; // Exam name shown at the top of the card
  final DateTime examDate; // Date shown below the exam name
  final double difficulty; // Current value shown on the slider
  final VoidCallback onDelete; // Removes this exam from the list
  final ValueChanged<double> onDifficultyChanged; // Sends the new slider value back to the screen
 
  const ExamPriorityCard({
    super.key,
    required this.name, // Receives the exam name
    required this.examDate, // Receives the selected exam date
    required this.difficulty, // Receives the current difficulty
    required this.onDelete, // Receives the delete action
    required this.onDifficultyChanged, // Receives the slider action
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: darkGreyColour, // Uses the dark card background
        borderRadius: BorderRadius.circular(12), // Rounds every corner of the card
        border: Border.all(color: borderColour), // Adds a faint outline around the card
      ),
      // Round Rectangular Card
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12), // Keeps the contents inside the rounded corners
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Accent left indicator border
              Container(
                width: 4, // Keeps the indicator narrow
                color: accentColour.withValues(alpha: 0.8), // Uses the accent accent colour
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0), // Adds space around the card contents
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Aligns the contents to the left
                    children: [
                      // Title row & Delete button icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Keeps the title and delete action apart
                        children: [
                          Expanded(
                            child: Text(
                              name, // Displays the exam name
                              style: TextStyle(
                                color: textPrimaryColour,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: onDelete, // Deletes the exam when tapped
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 6, 14, 0), // Gives the delete action a larger tap area
                              child: Column(
                                children: [
                                  Icon(Icons.delete_outline, size: 20, color: unselectedNavColour),
                                  const SizedBox(height: 2), // Adds a small gap below the delete icon
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: textSecondaryColour.withValues(alpha: 0.5), fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 4), // Adds space before the exam date

                      // Displays the date selected for this exam.
                      Text(
                        'Exam date: ${DateFormat('d MMMM yyyy').format(examDate)}',
                        style: TextStyle(
                          color: textSecondaryColour,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 16), // Adds space before the difficulty label
 
                      // Uses a 40-pixel total inset so the difficulty number lines up with the delete icon.
                      Padding(
                        padding: const EdgeInsets.only(right: 24), // Wrapped in Padding(right: 24) to match the Delete
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'DIFFICULTY (1-10)',
                              style: TextStyle(
                                color: accentColour,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              difficulty.toInt().toString(), // Displays the current difficulty as a whole number
                              style: TextStyle(
                                color: accentColour,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 12), // Adds space before the slider
 
                      // Difficulty Slider
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: highlightColour, // Colours the selected part of the slider
                          inactiveTrackColor: const Color.fromARGB(255, 111, 111, 111).withValues(alpha: 0.1), // Colours the remaining slider track
                          thumbColor: highlightColour, // Colours the draggable slider thumb
                          overlayColor: accentColour.withValues(alpha: 0.2), // Shows a soft colour while dragging
                          trackHeight: 4, // Keeps the slider track slim
                          // Draws a white ring behind the coloured slider thumb.
                          thumbShape: const _WhiteOutlineThumbShape(
                            enabledThumbRadius: 9,
                            borderWidth: 2,
                          ),
                          // Draws a short line instead of Flutter's default tick dot.
                          tickMarkShape: const _LineTickMarkShape(),
                          // Shrink the overlay so it doesn't add extra padding in the card
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        ),
                        child: Slider(
                          value: difficulty, // Uses the current difficulty value
                          min: 1, // Sets the lowest difficulty
                          max: 10, // Sets the highest difficulty
                          divisions: 9, // Creates one step for every whole number
                          onChanged: onDifficultyChanged, // Updates the difficulty while dragging
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
 
// Draws the slider thumb as a coloured circle sitting inside a white ring
class _WhiteOutlineThumbShape extends SliderComponentShape {
  final double enabledThumbRadius; // Controls the size of the coloured centre
  final double borderWidth; // Controls the thickness of the white outline
 
  const _WhiteOutlineThumbShape({
    this.enabledThumbRadius = 9, // Uses a compact thumb size by default
    this.borderWidth = 2, // Uses a thin white outline by default
  });
 
  @override
  // Calculates the total space required to draw the custom thumb
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(enabledThumbRadius + borderWidth);
  }
 
  @override
  // Handles the actual canvas drawing instructions for the thumb
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas; // Gets the canvas used to draw the thumb
 
    // Draws the outer white ring
    final Paint outlinePaint = Paint()
      ..color = textPrimaryColour
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, enabledThumbRadius + borderWidth, outlinePaint);
 
    // Inner coloured fill (uses thumbColor from SliderThemeData)
    final Paint fillPaint = Paint()
      ..color = sliderTheme.thumbColor ?? highlightColour
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, enabledThumbRadius, fillPaint);
  }
}
 
// Draws each slider division as a short vertical line.
class _LineTickMarkShape extends SliderTickMarkShape {
  final double lineWidth = 4; // Sets the thickness of each tick line
  final double lineHeight = 4; // Sets the height of each tick line
  
  const _LineTickMarkShape();
  
  @override
  // Calculates the space required for each tick mark
  Size getPreferredSize({
    required SliderThemeData sliderTheme,
    required bool isEnabled,
  }) {
    return Size(lineWidth, lineHeight);
  }
 
  @override
  // Handles the actual canvas drawing instructions for the tick marks
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    required bool isEnabled,
  }) {

    // Skip drawing a line directly under the thumb for a cleaner look.
    if ((center.dx - thumbCenter.dx).abs() < 1) return;
 
    final Canvas canvas = context.canvas; // Gets the canvas used to draw each tick
    final Paint paint = Paint()
      ..color = darkGreyColour
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    // Draws a precise vertical line at the centre point of the tick
    canvas.drawLine(
      Offset(center.dx, center.dy - lineHeight / 2),
      Offset(center.dx, center.dy + lineHeight / 2),
      paint,
    );
  }
}
