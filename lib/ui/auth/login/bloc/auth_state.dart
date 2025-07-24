import 'package:blog_app/data/models/app_user_model.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

/// New User Registration Start
class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final AppUser user;

  AuthSuccess(this.user);
}

class AuthFailure extends AuthState {
  final String message;

  AuthFailure(this.message);
}

/// New User Registration End

/// AuthOTP Start
class AuthOtpSent extends AuthState {
  final String email;
  final String password;
  final String name;
  AuthOtpSent(this.email, this.password, this.name);
}

/// AuthOTP End

/// Login Start
class LoginLoading extends AuthState {}

class LoginSuccess extends AuthState {
  final AppUser user;
  LoginSuccess(this.user);
}

class LoginFailure extends AuthState {
  final String message;

  LoginFailure(this.message);
}

/// Login End

/// Password Reset  Start
class ForgotPasswordLoaoding extends AuthState {}

class ForgotPasswordSuccess extends AuthState {}

class ForgotPasswordFailure extends AuthState {
  final String message;

  ForgotPasswordFailure(this.message);
}

/// Password Reset End
