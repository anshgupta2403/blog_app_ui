extension EmailValidator on String {
  bool get isValidEmail {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(trim());
  }
}

extension PasswordValidator on String {
  bool get isValidPassword {
    // At least 8 characters, one uppercase, one lowercase, one number, one symbol
    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$',
    );
    return passwordRegex.hasMatch(this);
  }
}

extension ConfirmPasswordValidator on String {
  bool isConfirming(String original) {
    return this == original;
  }
}

extension NameValidator on String {
  bool get isValidName {
    final nameRegex = RegExp(r'^[a-zA-Z\s]{2,50}$');
    return nameRegex.hasMatch(trim());
  }
}
