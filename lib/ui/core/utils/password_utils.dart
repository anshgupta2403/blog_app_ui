import 'package:flutter/material.dart';

class PasswordValidationResult {
  final String strength;
  final Color color;
  final double progress;

  PasswordValidationResult(this.strength, this.color, this.progress);
}

class PasswordUtils {
  static PasswordValidationResult validatePassword(String password) {
    int score = 0;

    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$&*~]').hasMatch(password)) score++;

    switch (score) {
      case 1:
        return PasswordValidationResult('Very Weak', Colors.red, 0.2);
      case 2:
        return PasswordValidationResult('Weak', Colors.orange, 0.4);
      case 3:
        return PasswordValidationResult('Medium', Colors.amber, 0.6);
      case 4:
        return PasswordValidationResult('Strong', Colors.lightGreen, 0.8);
      case 5:
        return PasswordValidationResult('Very Strong', Colors.green, 1.0);
      default:
        return PasswordValidationResult('', Colors.transparent, 0.0);
    }
  }
}
