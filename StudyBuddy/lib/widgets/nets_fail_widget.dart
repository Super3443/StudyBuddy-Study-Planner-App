import 'dart:async'; // Provides the Timer class
import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:mbap_project/providers/theme_provider.dart'; // Application theme colours

// Displays the failed payment message with a return countdown.
class NETSFailWidget extends StatefulWidget {
  final String? message; // Displays the payment failure returned by NETS
  final VoidCallback onFinished; // Returns after the countdown has finished

  const NETSFailWidget({
    super.key,
    required this.message,
    required this.onFinished,
  });

  @override
  State<NETSFailWidget> createState() => _NETSFailWidgetState();
}

class _NETSFailWidgetState extends State<NETSFailWidget> {
  Timer? _timer; // Updates the countdown every second
  int _countdown = 10; // Starts the return countdown at ten seconds

  @override
  void initState() {
    super.initState();
    _startCountdown(); // Begins the automatic return timer
  }

  // Reduces the countdown by one every second and returns when finished.
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);

        // Triggers the return callback when the countdown reaches zero.
        if (_countdown == 0) widget.onFinished();
      } else {
        timer.cancel(); // Stops the timer after the callback fires
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
          // Displays the failure icon inside a themed circle.
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.close_rounded,
              color: Colors.redAccent,
              size: 48,
            ),
          ),

          const SizedBox(height: 20),

          // Displays the failure heading.
          Text(
            'Payment Failed',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textPrimaryColour,
            ),
          ),

          const SizedBox(height: 8),

          // Displays the NETS failure reason when available.
          if (widget.message != null && widget.message!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textSecondaryColour.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

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