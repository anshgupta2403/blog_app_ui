import 'dart:async';
import 'dart:math';

import 'package:blog_app/core/Constants.dart';

class OtpManager {
  String? _otp;
  DateTime? _expiry;
  Timer? _expiryTimer;
  String? get otp => _otp;
  // Generate OTP and start expiry timer
  void generateOtp() {
    final length = Constants.OTP_LENGTH;
    Duration validity = Duration(minutes: Constants.OTP_EXPIRY_TIME);
    final random = Random.secure();
    _otp = List.generate(length, (_) => random.nextInt(10)).join();
    _expiry = DateTime.now().add(validity);

    _expiryTimer?.cancel(); // Cancel existing timer
    _expiryTimer = Timer(validity, () {
      clearOtp(); // Auto-expire after duration
      print('OTP expired');
    });
  }

  // Check validity
  bool verifyOtp(String inputOtp) {
    if (_otp == null || _expiry == null || DateTime.now().isAfter(_expiry!)) {
      clearOtp();
      return false; // Expired or invalid
    }

    final isValid = _otp == inputOtp;
    if (isValid) clearOtp();
    return isValid;
  }

  // Clear stored OTP
  void clearOtp() {
    _otp = null;
    _expiry = null;
    _expiryTimer?.cancel();
  }
}
