// lib/bloc/auth/auth_bloc.dart
import 'dart:async';
import 'package:blog_app/core/constants.dart';
import 'package:blog_app/data/repositories/auth_repository.dart';
import 'package:blog_app/ui/core/utils/otp_manager_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final OtpManager _otpManager;

  AuthBloc(this._authRepository, this._otpManager) : super(AuthInitial()) {
    on<LoginSubmitted>(_onLogin);
    on<OTPRequested>(_onOTPRequested);
    on<ForgotPasswordSubmitted>(_onForgotPassword);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<OtpSubmitted>(_onOtpSubmitted);
  }

  Future<void> _onLogin(LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(LoginLoading());
    try {
      final user = await _authRepository.login(event.email, event.password);
      if (user != null) {
        emit(LoginSuccess(user));
      } else {
        emit(LoginFailure('Login Failed'));
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          emit(LoginFailure('Email id is not registered'));
          break;
        case 'wrong-password':
          emit(LoginFailure('Incorrect password'));
          break;
        case 'network-request-failed':
          emit(LoginFailure('Please check your internet connection.'));
          break;
        default:
          emit(LoginFailure('Login Failed: Please try after some time'));
      }
    } catch (e) {
      emit(LoginFailure(e.toString()));
    }
  }

  Future<void> _onOTPRequested(
    OTPRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    _otpManager.generateOtp(); // OTP is now securely stored internally
    final otp = _otpManager.otp;
    final now = DateTime.now();
    final duration = Constants.OTP_EXPIRY_TIME;
    final time = now.add(Duration(minutes: duration));
    final formattedTime =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final emailSent = await _authRepository.sendOtpEmail(
      event.email,
      otp!,
      formattedTime,
      duration,
    );
    if (emailSent) {
      emit(
        AuthOtpSent(event.email, event.password, event.name),
      ); // Don't expose OTP here
    } else {
      emit(AuthFailure('Failed to send OTP email'));
    }
  }

  Future<void> _onForgotPassword(
    ForgotPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(ForgotPasswordLoaoding());
    try {
      await _authRepository.sendPasswordResetEmail(event.email);
      emit(ForgotPasswordSuccess());
    } on FirebaseAuthException catch (e) {
      emit(ForgotPasswordFailure('${e.message}'));
    } catch (e) {
      emit(ForgotPasswordFailure(e.toString()));
    }
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(LoginLoading());
    try {
      final user = await _authRepository.signInWithGoogle();
      if (user != null) {
        emit(LoginSuccess(user));
      } else {
        emit(LoginFailure('Google Sign-In failed'));
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          emit(LoginFailure('Already signed up with a different method'));
          break;
        case 'invalid-credential':
          emit(LoginFailure('Invalid Credcential'));
          break;
        case 'user-disabled':
          emit(LoginFailure('User has been disabled'));
          break;
        case 'network-request-failed':
          emit(LoginFailure('Network issue when signong in'));
          break;
        default:
          print('${e.message}');
          emit(LoginFailure('${e.message} Google Sign in failed'));
      }
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'sign_in_canceled':
          emit(LoginFailure('Sign in flow cancelled'));
          break;
        case 'sign_in_failed':
          emit(LoginFailure('Unknown error durign Google sign-in'));
          break;
        case 'network_error':
          emit(LoginFailure('No internet during Google account selection'));
          break;
        case 'popup_closed_by_user':
          emit(LoginFailure('User closed the pop up'));
          break;
        default:
          print('${e.message}');
          emit(LoginFailure('${e.message} Google Sign in failed'));
      }
    } catch (e) {
      print(e.toString());
      emit(LoginFailure(e.toString()));
    }
  }

  Future<void> _onOtpSubmitted(
    OtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    if (!_otpManager.verifyOtp(event.enteredOtp)) {
      emit(AuthFailure('Invalid or expired OTP'));
      return;
    }

    try {
      final user = await _authRepository.register(
        event.email,
        event.password,
        event.name,
      );
      if (user != null) {
        emit(LoginSuccess(user));
      } else {
        emit(LoginFailure('Registration Failed'));
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          emit(AuthFailure('The email is already registered'));
          break;
        case 'invalid-email':
          emit(AuthFailure('Invalid email-id'));
          break;
        case 'network-request-failed':
          emit(AuthFailure('Please check your internet connection.'));
        default:
          emit(AuthFailure('Registration Failed: Please try after some time'));
      }
    } catch (e) {
      emit(AuthFailure('Registration Failed: Please try after some time'));
    }
  }
}
