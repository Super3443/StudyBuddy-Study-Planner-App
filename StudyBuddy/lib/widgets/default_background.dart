import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:mbap_project/providers/theme_provider.dart'; // Application theme colours

// Reusable background component to ensure design consistency across multiple screens
class DefaultBackground extends StatelessWidget {
  final Widget child;

  const DefaultBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Full width to cover the entire screen
      height: double.infinity, // Full height to cover the entire screen
      decoration: BoxDecoration( // Removed const since colours are now dynamic
        gradient: RadialGradient( // Radial gradient to create a subtle glow effect
          center: Alignment(-0.8, -0.5), // Shifts the centre of the glow towards the top-left of the screen
          radius: 1.4, // Increases the size of the glow radius to cover a large area
          colors: [
            Color.lerp(blackColour, accentColour, 0.05)!, // Mixes 5% accent into the base colour
            blackColour, // Base surface colour from the active mode
          ],
          stops: [0.0, 0.8], // Defines exactly where the colour transition begins (0.0) and finishes (0.8)
        ),
      ),
      child: child, // Places the passed widget inside this styled container
    );
  }
}