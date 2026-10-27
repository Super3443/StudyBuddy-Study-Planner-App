import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Watches AI access state
import 'package:mbap_project/providers/ai_access_provider.dart'; // Reads the current plan tier
import 'package:mbap_project/providers/theme_provider.dart'; // Application theme colours
import 'package:mbap_project/screens/ai_pro_purchase.dart'; // Opens the NETS payment screen

// Displays the available AI plan tiers for the user to choose from.
class AiPlanSelectionScreen extends ConsumerWidget {
  static const String routeName = '/ai-plan-selection'; // Named route for navigation
  const AiPlanSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeProvider); // Rebuilds when the colour scheme changes
    
    // Reads the current plan tier to disable already-purchased plans.
    final accessState = ref.watch(aiAccessProvider);
    final currentTier = accessState.proTier;

    // Maps each tier to a numeric rank for comparison.
    const tierRank = {'free': 0, 'standard': 1, 'premium': 2};
    final currentRank = tierRank[currentTier] ?? 0;

    return Scaffold(
      backgroundColor: blackColour, // Matches the main app background
      body: SafeArea(
        // Prevents UI elements from overlapping with device status bars.
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
              child: Row(
                children: [
                  // Returns to the previous screen when tapped.
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: textPrimaryColour),
                  ),
                  Expanded(
                    child: Text(
                      'Choose Your Plan',
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

            // --- PLAN CONTENT ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  children: [
                    // Displays the current plan status at the top.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: accentColour.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentColour.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            color: accentColour,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Current plan: ${accessState.tierDisplayName}',
                            style: TextStyle(
                              color: accentColour,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Short subtitle explaining the upgrade benefits.
                    Text(
                      'Unlock more AI-generated study schedules with a one-time purchase.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textSecondaryColour,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // --- STANDARD PLAN CARD ---
                    _PlanCard(
                      icon: Icons.bolt_rounded,
                      iconColour: const Color(0xFFFFA726), // Warm amber bolt
                      tierName: 'Standard',
                      promptsLabel: '25 prompts per day',
                      price: 9.99,
                      tier: 'standard',
                      isCurrentPlan: currentTier == 'standard',
                      isDisabled: currentRank >= 1, // Disabled when already standard or premium
                      onPurchase: () => _openPayment(
                        context,
                        tier: 'standard',
                        price: 9.99,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- PREMIUM PLAN CARD ---
                    _PlanCard(
                      icon: Icons.diamond_rounded,
                      iconColour: const Color(0xFFAB47BC), // Rich purple diamond
                      tierName: 'Premium',
                      promptsLabel: 'Unlimited prompts',
                      price: 29.99,
                      tier: 'premium',
                      isCurrentPlan: currentTier == 'premium',
                      isDisabled: currentRank >= 2, // Disabled when already premium
                      isPremium: true, // Applies the highlighted card style
                      onPurchase: () => _openPayment(
                        context,
                        tier: 'premium',
                        price: 29.99,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- FREE TIER INFORMATION ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: darkGreyColour,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: borderColour,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: labelColour,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Free accounts receive 1 generation per day.',
                              style: TextStyle(
                                color: labelColour,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  // Opens the NETS payment screen for the selected plan.
  Future<void> _openPayment(
    BuildContext context, {
    required String tier,
    required double price,
  }) async {
    // Navigates to the payment screen with the selected tier and price.
    final purchaseResult = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AiProPurchaseScreen(tier: tier, price: price),
      ),
    );

    // Stops when the payment screen was cancelled or the widget was removed.
    if (!context.mounted) return;

    // Returns the successful result to whichever screen opened plan selection.
    if (purchaseResult == true) {
      Navigator.pop(context, true);
    }
  }
}

// Displays one plan tier as a styled card with icon, details and purchase button.
class _PlanCard extends StatelessWidget {
  final IconData icon; // Stores the tier icon displayed at the top
  final Color iconColour; // Stores the icon background colour
  final String tierName; // Stores the plan tier display name
  final String promptsLabel; // Stores the daily prompt allowance text
  final double price; // Stores the one-time purchase price
  final String tier; // Stores the tier key passed to the payment screen
  final bool isCurrentPlan; // Shows the "Current Plan" label when active
  final bool isDisabled; // Disables the purchase button for owned or lower tiers
  final bool isPremium; // Applies the highlighted border style
  final VoidCallback onPurchase; // Opens the payment screen when tapped

  const _PlanCard({
    required this.icon,
    required this.iconColour,
    required this.tierName,
    required this.promptsLabel,
    required this.price,
    required this.tier,
    required this.isCurrentPlan,
    required this.isDisabled,
    required this.onPurchase,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: darkGreyColour,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          // Uses a brighter border for the premium card to make it stand out.
          color: isPremium
              ? accentColour.withValues(alpha: 0.5)
              : textSecondaryColour,
          width: isPremium ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // --- TIER ICON ---
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColour.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColour, size: 30),
          ),

          const SizedBox(height: 16),

          // --- TIER NAME ---
          Text(
            tierName,
            style: TextStyle(
              color: textPrimaryColour,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // --- PROMPT ALLOWANCE ---
          Text(
            promptsLabel,
            style: TextStyle(
              color: accentColour.withValues(alpha: 0.85),
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 16),

          // --- PRICE ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: textPrimaryColour,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'one-time',
                  style: TextStyle(
                    color: labelColour,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- PURCHASE BUTTON OR CURRENT PLAN LABEL ---
          if (isCurrentPlan)
            // Shows a disabled label when this tier is already active.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: accentColour.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: accentColour.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Current Plan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accentColour,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            // Shows the purchase button for tiers the user can upgrade to.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isDisabled ? null : onPurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColour,
                  disabledBackgroundColor: accentColour.withValues(alpha: 0.3),
                  foregroundColor: deepAccentColour,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  isDisabled ? 'Already Owned' : 'Purchase',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}