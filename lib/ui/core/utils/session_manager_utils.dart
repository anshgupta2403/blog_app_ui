import 'package:blog_app/data/models/app_user_model.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  AppUser? _currentUser;

  void setUser(AppUser user) {
    _currentUser = AppUser.fromFirebaseAppUser(user);
  }

  void clearUser() {
    _currentUser = null;
  }

  AppUser? get currentUser => _currentUser;
}
