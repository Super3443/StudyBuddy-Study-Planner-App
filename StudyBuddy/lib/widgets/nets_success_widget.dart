import 'dart:async'; // Provides the Timer class
import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:mbap_project/providers/theme_provider.dart'; // Application theme colours

// Displays the successful payment confirmation with a return countdown.
class NETSSuccessWidget extends StatefulWidget {
  const NETSSuccessWidget({super.key});

  @override
  State<NETSSuccessWidget> createState() => _NETSSuccessWidgetState();
}

class _NETSSuccessWidgetState extends State<NETSSuccessWidget> {
  Timer? _timer; // Updates the countdown every second
  int _countdown = 10; // Starts the return countdown at ten seconds

  @override
  void initState() {
    super.initState();

    // Reduces the countdown by one every second.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel(); // Stops the timer after the countdown finishes
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Stops the timer when the widget is removed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          // Displays the success icon inside a themed circle.
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.green,
              size: 48,
            ),
          ),

          const SizedBox(height: 20),

          // Displays the success heading.
          Text(
            'Payment Successful',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textPrimaryColour,
            ),
          ),

          const SizedBox(height: 8),

          // Displays the confirmation message.
          Text(
            'Your plan has been upgraded successfully.',
            style: TextStyle(
              color: textPrimaryColour.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),

          // Displays the return countdown in a styled chip.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: darkGreyColour,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColour.withValues(alpha: 0.08),
              ),
            ),
            child: Text(
              'Returning in $_countdown seconds',
              style: TextStyle(
                color: textSecondaryColour.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}