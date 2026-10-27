import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod state management
import 'package:mbap_project/providers/biometric_provider.dart'; // Biometric verification provider
import 'package:mbap_project/providers/firebase_provider.dart'; // Firebase authentication provider
import 'package:mbap_project/main.dart'; // MainScreen widget

// Checks fingerprint verification before granting access to the main screen
class BiometricGate extends ConsumerStatefulWidget {
  const BiometricGate({super.key});

  @override
  ConsumerState<BiometricGate> createState() => _BiometricGateState();
}

// Holds the mutable state and biometric verification logic
class _BiometricGateState extends ConsumerState<BiometricGate> {
  // Tracks whether the user has passed fingerprint verification
  bool _verified = false;

  // Tracks whether the biometric check is still in progress
  bool _checking = true;

  @override
  void initState() {
    super.initState();

    // Starts the biometric verification check when the widget first loads
    _checkBiometric();
  }

  // Determines whether the user needs fingerprint verification and prompts if enabled
  Future<void> _checkBiometric() async {
    // Reads the biometric provider to access verification methods
    final biometric = ref.read(biometricProvider);

    // Retrieves the currently signed-in user's ID
    final userId = biometric.currentUserId;

    // Skips verification if no user is found
    if (userId == null) {
      setState(() {
        _verified = true; // Marks verification as passed
        _checking = false; // Stops the loading spinner
      });
      return;
    }

    // Checks whether the user has enabled biometric verification in their settings
    final enabled = await biometric.isEnabled(userId);

    // Skips verification if the user has not enabled biometrics
    if (!enabled) {
      // Prevents crashes if the user navigates away during the check
      if (mounted) {
        setState(() {
          _verified = true; // Marks verification as passed
          _checking = false; // Stops the loading spinner
        });
      }
      return;
    }

    // Stores the result of the fingerprint authentication attempt
    bool authenticated = false;

    try {
      // Prompts the device's fingerprint scanner for user verification
      authenticated = await biometric.authenticate();
    } catch (_) {
      // Treats a cancelled or failed biometric prompt as a failed attempt
      authenticated = false;
    }

    if (authenticated) {
      // Prevents crashes if the user navigates away during the check
      if (mounted) {
        setState(() {
          _verified = true; // Marks verification as passed
          _checking = false; // Stops the loading spinner
        });
      }
    } else {
      // Signs the user out if fingerprint verification fails or is cancelled
      await ref.read(firebaseServiceProvider).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Displays a loading spinner while the biometric check is in progress
    if (_checking || !_verified) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Grants access to the main screen after successful verification
    return const MainScreen();
  }
}