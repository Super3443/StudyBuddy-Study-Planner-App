import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbap_project/services/biometric_service.dart';

final biometricServiceProvider = Provider((ref) => BiometricService());

final biometricProvider = Provider((ref) {
  final service = ref.read(biometricServiceProvider);
  return BiometricProvider(service);
});

class BiometricProvider {
  final BiometricService _service;

  BiometricProvider(this._service);

  String? get currentUserId => _service.currentUserId;
  Future<bool> isDeviceSupported() => _service.isDeviceSupported();
  Future<bool> authenticate() => _service.authenticate();
  Future<bool> isEnabled(String userId) => _service.isEnabled(userId);
  Future<void> setEnabled(String userId, bool value) => _service.setEnabled(userId, value);
}