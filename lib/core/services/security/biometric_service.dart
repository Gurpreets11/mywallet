import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Thin wrapper around `local_auth` (fingerprint / face unlock).
///
/// Biometrics only ever *add* a shortcut: the PIN always keeps working, and
/// the PIN is still required to turn the lock on.
class BiometricService {
  BiometricService._();

  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// True when the device has biometric hardware with something enrolled.
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } on PlatformException catch (e) {
      debugPrint('Biometric check failed: $e');
      return false;
    } catch (e) {
      debugPrint('Biometric check failed: $e');
      return false;
    }
  }

  /// Shows the system prompt. Returns false when cancelled, failed or
  /// unavailable (never throws).
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication failed: $e');
      return false;
    } catch (e) {
      debugPrint('Biometric authentication failed: $e');
      return false;
    }
  }
}
