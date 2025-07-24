abstract class AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  LoginSubmitted({required this.email, required this.password});
}

class OTPRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  OTPRequested({
    required this.email,
    required this.password,
    required this.name,
  });
}

class ForgotPasswordSubmitted extends AuthEvent {
  final String email;

  ForgotPasswordSubmitted(this.email);
}

class AuthGoogleSignInRequested extends AuthEvent {}

class OtpSubmitted extends AuthEvent {
  final String email;
  final String password;
  final String enteredOtp;
  final String name;
  OtpSubmitted({
    required this.email,
    required this.password,
    required this.enteredOtp,
    required this.name,
  });
}
