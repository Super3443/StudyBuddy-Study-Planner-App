import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Watches NETS payment state
import 'package:mbap_project/providers/nets_provider.dart'; // Manages the NETS payment flow
import 'package:mbap_project/providers/theme_provider.dart'; // Application theme colours
import 'package:mbap_project/widgets/nets_widget.dart'; // Displays the QR code and payment status

// Displays the NETS QR flow for the selected plan purchase.
class AiProPurchaseScreen extends ConsumerStatefulWidget {
  final String tier; // Stores the plan tier being purchased
  final double price; // Stores the price for the selected tier

  const AiProPurchaseScreen({
    super.key,
    required this.tier,
    required this.price,
  });

  @override
  ConsumerState<AiProPurchaseScreen> createState() =>
      _AiProPurchaseScreenState();
}

// Manages returning to the plan selection screen after the payment flow finishes.
class _AiProPurchaseScreenState extends ConsumerState<AiProPurchaseScreen> {
  bool _isClosing = false; // Prevents repeated navigation callbacks

  // Clears the payment state and returns the result to the plan selection screen.
  void _closePayment(bool wasSuccessful) {
    // Stops another timer or callback from closing the screen twice.
    if (_isClosing || !mounted) return;

    _isClosing = true; // Marks the payment screen as closing
    ref.read(netsProvider.notifier).cleanup(); // Clears the NETS payment state
    Navigator.pop(context, wasSuccessful); // Returns the payment result
  }

  @override
  void dispose() {
    // Clears an active QR payment when the device back action closes the screen.
    if (!_isClosing) ref.read(netsProvider.notifier).cleanup();
    super.dispose(); // Releases the payment screen state
  }

  // Returns a display-friendly name for the selected tier.
  String get _tierDisplayName {
    switch (widget.tier) {
      case 'premium':
        return 'Premium';
      case 'standard':
        return 'Standard';
      default:
        return 'Plan';
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider); // Rebuilds when the colour scheme changes
    
    // Watches the payment status used for the complete screen transition.
    final paymentState = ref.watch(netsProvider);

    // Returns automatically after the success countdown has completed.
    if (paymentState.status == 'complete' && !_isClosing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _closePayment(true); // Returns a successful payment result
      });
    }

    return Scaffold(
      backgroundColor: blackColour, // Matches the main app background
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
              child: Row(
                children: [
                  // Returns to the plan selection screen when tapped.
                  IconButton(
                    onPressed: () => _closePayment(false),
                    icon: Icon(Icons.arrow_back, color: textPrimaryColour),
                  ),
                  Expanded(
                    child: Text(
                      'Purchase $_tierDisplayName',
                      style: TextStyle(
                        color: textPrimaryColour,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- DIVIDER ---
            Divider(color: dividerColour),

            // --- PAYMENT CONTENT ---
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Displays the selected plan summary above the QR code.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: darkGreyColour,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: accentColour.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Displays the tier icon matching the plan selection.
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: accentColour.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                widget.tier == 'premium'
                                    ? Icons.diamond_rounded
                                    : Icons.bolt_rounded,
                                color: accentColour,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Displays the plan name.
                                  Text(
                                    '$_tierDisplayName Plan',
                                    style: TextStyle(
                                      color: textPrimaryColour,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  // Displays the plan price.
                                  Text(
                                    '\$${widget.price.toStringAsFixed(2)} one-time purchase',
                                    style: TextStyle(
                                      color: textSecondaryColour,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Displays the NETS QR code and payment status.
                    NETSWidget(
                      price: widget.price,
                      tier: widget.tier,
                      tierDisplayName: _tierDisplayName,
                      onCancel: () => _closePayment(false),
                      onFailure: () => _closePayment(false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}