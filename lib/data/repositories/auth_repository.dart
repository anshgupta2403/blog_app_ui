import 'package:blog_app/data/models/app_user_model.dart';
import 'package:blog_app/data/service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  Future<AppUser?> login(String email, String password) async {
    User? user = await _authService.signIn(email, password);
    return AppUser(
      uid: user?.uid,
      name: user?.displayName,
      email: user?.email,
      photoUrl: user?.photoURL,
    );
  }

  Future<AppUser?> register(String email, String password, String name) async {
    User? user = await _authService.register(email, password, name);
    return AppUser(
      uid: user?.uid,
      name: user?.displayName,
      email: user?.email,
      photoUrl: user?.photoURL,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _authService.resetPassword(email);
  }

  Future<AppUser?> signInWithGoogle() async {
    User? user = await _authService.signInWithGoogle();
    return AppUser(
      uid: user?.uid,
      name: user?.displayName,
      email: user?.email,
      photoUrl: user?.photoURL,
    );
  }

  Future<bool> sendOtpEmail(
    String email,
    String otp,
    String time,
    int duration,
  ) {
    return _authService.sendOtpEmail(email, otp, time, duration);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    return _authService.sendPasswordResetEmail(email);
  }
}
