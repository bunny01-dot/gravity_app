import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class BiometricService {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint("Biometric Error: $e");
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await auth.authenticate(
        localizedReason: 'Scan to verify your identity',
        // options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
    } on PlatformException catch (e) {
      debugPrint("Authentication Error: $e");
      return false;
    }
  }
}
