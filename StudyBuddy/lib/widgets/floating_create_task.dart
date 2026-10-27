import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:mbap_project/providers/theme_provider.dart';

// The central floating action button with the glow effect.
// with floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked
class NavAddTask extends StatelessWidget {
  // Callback function triggered when the button is tapped
  final VoidCallback onPressed;

  const NavAddTask({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    // Outer container to apply the shadow effect
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              // Creates the accent glow effect seen in the design
              BoxShadow(
                color: highlightColour.withValues(alpha: 0.4),
                blurRadius: 10, // Softness of the shadow
                spreadRadius: 2, // Size expansion of the shadow
              ),
            ],
          ),
          // Constrains the floating button to a specific large size
          child: SizedBox(
            width: 75,
            height: 75,
            child: FloatingActionButton(
              onPressed: onPressed,
              backgroundColor: highlightColour,
              // Removes default material shadows to rely entirely on the custom glow above
              elevation: 0,
              shape: const CircleBorder(),
              child: Icon(Icons.assignment, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Create Task',
          style: TextStyle(
            color: textPrimaryColour,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}