import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mbap_project/models/nets_state.dart';
import 'package:mbap_project/providers/ai_access_provider.dart';
import 'package:mbap_project/providers/firebase_provider.dart';
import 'package:mbap_project/services/nets_service.dart';

// Provides the service that communicates with the NETS sandbox.
final netsServiceProvider = Provider<NETSService>((ref) {
  return NETSService(); // Creates the NETS service when it is first needed
});

// Exposes the NETS payment state and payment actions throughout the app.
final netsProvider = StateNotifierProvider<NetsController, NetsState>((ref) {
  // Recreates the payment flow whenever the signed-in account changes.
  ref.watch(authStateProvider);

  // Gets the service that requests QR codes and checks payments.
  final service = ref.read(netsServiceProvider);

  // Gets the access notifier that updates the Pro entitlement in Firestore.
  final aiAccessNotifier = ref.read(aiAccessProvider.notifier);

  // Creates the payment controller with its required dependencies.
  return NetsController(
    service: service, // Supplies the NETS sandbox service
    aiAccessNotifier: aiAccessNotifier, // Supplies the Firestore access actions
  );
});

// Manages the NETS QR payment flow, timer and payment confirmation.
class NetsController extends StateNotifier<NetsState> {
  final NETSService service; // Sends QR and payment requests to NETS
  final AiAccessNotifier
  aiAccessNotifier; // Saves confirmed Pro access to Firestore

  Timer? _timer; // Updates the QR expiry countdown every second
  bool _isCheckingPayment = false; // Prevents overlapping payment checks
  bool _hasFinishedPayment = false; // Prevents duplicate entitlement updates
  String _selectedTier = 'standard'; // Stores the tier being purchased

  // Starts with the initial NETS state and receives its dependencies.
  NetsController({required this.service, required this.aiAccessNotifier})
    : super(NetsState());

  // Generates a fresh QR code for the one-time AI Pro purchase.
  Future<void> generateQR({required double price, required String tier}) async {
    // Stores the selected tier for use when the payment succeeds.
    _selectedTier = tier;
    // Stops the previous timer before a new QR payment starts.
    _timer?.cancel();

    // Resets the payment guards for the new QR transaction.
    _isCheckingPayment = false;
    _hasFinishedPayment = false;

    // Displays the loading state while NETS creates the QR code.
    state = NetsState(status: 'loading');

    try {
      // Requests a QR code for the selected plan price.
      final decoded = await service.requestQR(price);

      // Reads the QR image and transaction reference returned by NETS.
      final encodedQrCode = decoded['qrCode'] as String?;
      final transactionReference = decoded['txnRef'] as String?;

      // Stops before decoding incomplete NETS response data.
      if (encodedQrCode == null ||
          encodedQrCode.isEmpty ||
          transactionReference == null ||
          transactionReference.isEmpty) {
        throw const FormatException('NETS did not return a valid QR payment.');
      }

      // Converts the Base64 QR image into bytes for Image.memory.
      final qrCode = base64Decode(encodedQrCode);

      // Shows the active QR code and starts its five-minute countdown.
      state = NetsState(
        qrCode: qrCode, // Stores the decoded QR image
        status: 'idle', // Marks the QR code as ready to scan
        timeLeft: 300, // Gives the QR code five minutes to complete
        txnRef: transactionReference, // Stores the NETS transaction reference
      );

      // Starts the countdown and listens for NETS scan updates.
      startTimer(transactionReference);
      startWebhookListener(transactionReference);
    } catch (_) {
      // Shows a safe failure state when NETS cannot create a usable QR code.
      state = NetsState(
        status: 'fail', // Marks the QR request as unsuccessful
        message: 'Unable to create a NETS QR payment. Please try again.',
      );
    }
  }

  // Runs the five-minute QR countdown from the NETS payment flow.
  void startTimer(String transactionReference) {
    // Cancels an earlier timer before starting the current transaction timer.
    _timer?.cancel();

    // Updates the remaining QR time once every second.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Stops when this timer no longer belongs to the active QR transaction.
      if (state.status != 'idle' || state.txnRef != transactionReference) {
        timer.cancel();
        return;
      }

      // Reduces the visible countdown while the QR code is still active.
      if (state.timeLeft > 0) {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
        return;
      }

      // Stops the timer before checking the final NETS payment result.
      timer.cancel();
      checkPayment(transactionReference);
    });
  }

  // Listens for the NETS Server-Sent Event scan notification.
  Future<void> startWebhookListener(String transactionReference) async {
    try {
      // Reads every live update sent by the NETS webhook stream.
      await for (final data in service.webhookStream(transactionReference)) {
        // Stops when Riverpod has disposed this payment controller.
        if (!mounted) return;

        // Checks the payment after NETS reports that the QR code was scanned.
        if (data.contains('QR code scanned')) {
          state = state.copyWith(message: 'QR code scanned');
          await checkPayment(transactionReference);
          return;
        }
      }
    } catch (_) {
      // Keeps the QR active because the timer will run the fallback payment check.
    }
  }

  // Checks the final NETS payment status for the active transaction.
  Future<void> checkPayment(String transactionReference) async {
    // Ignores repeated checks after a result is already being processed.
    if (_isCheckingPayment || _hasFinishedPayment) return;

    // Ignores a late response for a QR transaction that is no longer active.
    if (state.txnRef != transactionReference) return;

    // Blocks the timer and webhook from starting another check at the same time.
    _isCheckingPayment = true;

    try {
      // Retrieves the final response code and message from NETS.
      final decoded = await service.checkPayment(transactionReference);
      final responseCode = decoded['response_code'] as String? ?? '99';
      final responseMessage = decoded['message'] as String?;

      // Stores the latest NETS message when the sandbox returns one.
      if (responseMessage != null && responseMessage.isNotEmpty) {
        state = state.copyWith(message: responseMessage);
      }

      // Handles the successful NETS response code.
      if (responseCode == '00') {
        // Prevents another check or entitlement update for this payment.
        _hasFinishedPayment = true;

        // Stops the QR timer because NETS has confirmed the payment.
        _timer?.cancel();

        // Saves the purchased plan tier using the confirmed reference.
        await aiAccessNotifier.grantAiProAccess(
          transactionReference,
          _selectedTier,
        );
        
        // Stops when the controller was disposed while Firestore was updating.
        if (!mounted) return;

        // Shows the successful payment state for ten seconds.
        state = state.copyWith(
          status: 'success', // Displays the successful payment widget
          message: 'AI Pro activated successfully.', // Confirms the entitlement
        );

        // Keeps the successful state visible for the required countdown period.
        await Future.delayed(const Duration(seconds: 10));

        // Stops when the controller was disposed during the success delay.
        if (!mounted) return;

        // Marks the completed payment flow for its parent screen.
        state = state.copyWith(status: 'complete');
        return;
      }

      // Stops the QR timer after NETS returns an unsuccessful final result.
      _timer?.cancel();

      // Shows the failed payment state for an unsuccessful result.
      state = state.copyWith(
        status: 'fail', // Displays the failed payment widget
        message:
            responseMessage ??
            'The NETS payment was not completed.', // Explains the result
      );
    } catch (_) {
      // Stops the QR timer when the payment result cannot be confirmed.
      _timer?.cancel();

      // Shows a safe failure state without granting Pro access.
      state = state.copyWith(
        status: 'fail', // Displays the failed payment widget
        message: 'Unable to confirm the NETS payment. Please try again.',
      );
    } finally {
      // Allows a new payment check only when the current payment was not final.
      _isCheckingPayment = false;
    }
  }

  // Cancels the timer and clears the current payment state.
  void cleanup() {
    // Stops the active QR countdown when the payment flow is closed.
    _timer?.cancel();

    // Clears the guards before another QR transaction can start.
    _isCheckingPayment = false;
    _hasFinishedPayment = false;

    // Restores the initial state without a QR image or transaction reference.
    state = NetsState();
  }

  @override
  void dispose() {
    // Stops the active timer before Riverpod removes this controller.
    _timer?.cancel();
    super.dispose();
  }
}
