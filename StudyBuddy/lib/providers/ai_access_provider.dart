import 'package:flutter_riverpod/legacy.dart';
import 'package:mbap_project/models/ai_access_state.dart';
import 'package:mbap_project/providers/firebase_provider.dart';
import 'package:mbap_project/services/firebase_service.dart';

// Manages AI access checks and updates through FirebaseService.
class AiAccessNotifier extends StateNotifier<AiAccessState> {
  final FirebaseService firebaseService; // Handles the Firestore operations

  // Starts with an empty access state and receives the Firebase service.
  AiAccessNotifier({required this.firebaseService})
    : super(const AiAccessState());

  // Loads the current plan tier and daily generation data from Firestore.
  Future<void> loadAccess() async {
    // Shows that the account access details are being retrieved.
    state = state.copyWith(status: 'loading', clearMessage: true);

    try {
      // Reads the active plan tier from the user document.
      final proTier = await firebaseService.getProTier();

      // Reads the daily generation count and date from the user document.
      final generationData = await firebaseService.getDailyGenerationData();

      // Publishes the complete access details after both checks succeed.
      state = AiAccessState(
        proTier: proTier, // Stores the active plan tier
        dailyGenerationCount:
            generationData['count'] as int, // Stores the daily count
        lastGenerationDate:
            generationData['date'] as DateTime?, // Stores the generation date
        status: 'ready', // Confirms that access can now be checked
      );
    } catch (error) {
      // Keeps generation blocked until the access check can be completed.
      state = state.copyWith(
        status: 'error', // Marks the Firestore check as unsuccessful
        message: error.toString(), // Stores the reason for the failure
      );
    }
  }

  // Records a completed generation and updates the daily counter.
  Future<void> recordGeneration() async {
    // Premium accounts track generations but have no daily cap.
    // Free and standard accounts both use the daily counter.

    // Saves the generation and receives the updated counter values.
    final result = await firebaseService.recordGeneration();

    // Stores the updated counter locally for an immediate access check.
    state = state.copyWith(
      dailyGenerationCount: result['count'] as int, // Updates the daily count
      lastGenerationDate:
          result['date'] as DateTime, // Updates the generation date
      status: 'ready', // Keeps the access state ready after saving
      clearMessage: true, // Removes an earlier access error
    );
  }

  // Grants a paid plan after a confirmed NETS payment.
  Future<void> grantAiProAccess(
    String transactionReference,
    String tier,
  ) async {
    // Removes unnecessary spaces from the NETS transaction reference.
    final cleanedReference = transactionReference.trim();

    // Stops an empty reference from being stored as a successful purchase.
    if (cleanedReference.isEmpty) {
      throw ArgumentError('A NETS transaction reference is required.');
    }

    // Saves the confirmed purchase through FirebaseService.
    await firebaseService.grantAiProAccess(
      transactionReference: cleanedReference, // Stores the NETS reference
      tier: tier, // Stores the purchased plan tier
    );

    // Enables the purchased plan immediately after Firestore is updated.
    state = state.copyWith(
      proTier: tier, // Activates the purchased plan tier
      status: 'ready', // Keeps the access state ready after payment
      clearMessage: true, // Removes an earlier access error
    );
  }
}

// Exposes AI access state and actions throughout the app.
final aiAccessProvider = StateNotifierProvider<AiAccessNotifier, AiAccessState>(
  (ref) {
    // Recreates the access state whenever the signed-in account changes.
    ref.watch(authStateProvider);

    // Gets the existing service that owns all Firebase operations.
    final firebaseService = ref.read(firebaseServiceProvider);

    // Creates the notifier without loading data before it is watched.
    final notifier = AiAccessNotifier(firebaseService: firebaseService);

    // Starts the Firestore access check when the provider is first created.
    notifier.loadAccess();

    // Returns the configured notifier to Riverpod.
    return notifier;
  },
);