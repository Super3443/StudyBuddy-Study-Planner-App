import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  // Returns the current user's UID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  Future<bool> isDeviceSupported() async {
    return await _auth.canCheckBiometrics;
  }

  Future<bool> authenticate() async {
    return await _auth.authenticate(
      localizedReason: 'Verify your identity to continue',
      biometricOnly: true,
    );
  }

  // Reads the biometric setting from Firestore
  Future<bool> isEnabled(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    return doc.data()?['biometric_enabled'] ?? false;
  }

  // Updates the biometric setting in Firestore
  Future<void> setEnabled(String userId, bool value) async {
    // Changes only the biometric toggle without affecting other user fields.
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'biometric_enabled': value});
  }
}