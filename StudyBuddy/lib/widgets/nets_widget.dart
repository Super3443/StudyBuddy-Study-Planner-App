import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Watches NETS payment state
import 'package:mbap_project/providers/nets_provider.dart'; // Manages the NETS payment flow
import 'package:mbap_project/providers/theme_provider.dart'; // Application theme colours
import 'package:mbap_project/widgets/nets_fail_widget.dart'; // Displays the failure state
import 'package:mbap_project/widgets/nets_success_widget.dart'; // Displays the success state

// Displays the NETS QR code, countdown timer and payment status.
class NETSWidget extends ConsumerStatefulWidget {
  final double price; // Stores the price for the selected plan
  final String tier; // Stores the tier key for the NETS provider
  final String tierDisplayName; // Stores the display name for the payment header
  final VoidCallback onCancel; // Returns to the previous screen when cancelled
  final VoidCallback onFailure; // Returns after the failure countdown finishes

  const NETSWidget({
    super.key,
    required this.price,
    required this.tier,
    required this.tierDisplayName,
    required this.onCancel,
    required this.onFailure,
  });

  @override
  ConsumerState<NETSWidget> createState() => _NETSWidgetState();
}

class _NETSWidgetState extends ConsumerState<NETSWidget> {
  @override
  void initState() {
    super.initState();

    // Generates the QR code for the selected plan when the widget first builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(netsProvider.notifier).generateQR(
        price: widget.price,
        tier: widget.tier,
      );
    });
  }

  // Formats seconds into a minutes and seconds display.
  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(netsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      width: double.infinity,
      child: Column(
        children: [
          // --- LOADING STATE ---
          if (state.status == "loading") ...[
            const SizedBox(height: 60),
            CircularProgressIndicator(color: accentColour),
            const SizedBox(height: 20),
            Text(
              'Creating your NETS QR code...',
              style: TextStyle(
                color: textSecondaryColour,
                fontSize: 15,
              ),
            ),
          ],

          // --- QR CODE ACTIVE ---
          if (state.status == "idle" && state.qrCode != null) ...[
            const SizedBox(height: 8),

            // Instruction text above the QR code.
            Text(
              'Scan with TWallet to complete your purchase',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondaryColour,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 20),

            // Styled QR code container with rounded corners.
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: textPrimaryColour,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.memory(
                state.qrCode!,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 16),

            // Displays the NETS information image.
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12), // Rounds the image corners
                child: Image.asset(
                  'images/nets_qr_info.png',
                  width: MediaQuery.of(context).size.width * 1.0,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Countdown timer styled with the app theme.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: darkGreyColour,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: borderColour.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: accentColour.withValues(alpha: 0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatTime(state.timeLeft),
                    style: TextStyle(
                      color: state.timeLeft <= 30
                          ? Colors.redAccent // Highlights the final 30 seconds
                          : textSecondaryColour,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Cancel button styled with the app theme.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColour, // Uses the theme accent colour for the button text
                  side: BorderSide(
                    color: accentColour.withValues(alpha: 0.6), // Uses a softer accent border
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Cancel Payment',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ),
          ],

          // --- SUCCESS STATE ---
          if (state.status == "success")
            const NETSSuccessWidget(),

          // --- FAILURE STATE ---
          if (state.status == "fail")
            NETSFailWidget(
              message: state.message,
              onFinished: widget.onFailure,
            ),
        ],
      ),
    );
  }
}