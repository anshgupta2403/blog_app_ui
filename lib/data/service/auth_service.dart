import 'dart:convert';

import 'package:blog_app/data/models/app_user_model.dart';
import 'package:blog_app/data/service/firebase_notifications_service.dart';
import 'package:blog_app/ui/core/utils/session_manager_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseNotificationsService _firebaseNotificationsService =
      FirebaseNotificationsService();
  final serviceId = 'service_1f6rhrt';
  final templateId = 'template_7em95vh';
  final userId = 'BRJR8VQFj4REbSzLc';

  Future<User?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    _firebaseNotificationsService.initNotifications();
    _saveCurrentUser(result.user?.uid);
    return result.user;
  }

  Future<User?> register(String email, String password, String name) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = result.user;
    _addNewUserToUsersCollection(
      email: user?.email,
      name: name,
      createdAt: DateTime.timestamp(),
      uid: user?.uid,
      profileImageUrl: '',
    );
    _firebaseNotificationsService.initNotifications();
    _saveCurrentUser(user?.uid);
    return user;
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    if (result.user != null) {
      _addNewUserToUsersCollection(
        email: result.user?.email,
        name: result.user?.displayName,
        createdAt: DateTime.timestamp(),
        uid: result.user?.uid,
        profileImageUrl: result.user?.photoURL,
      );
      _firebaseNotificationsService.initNotifications();
      _saveCurrentUser(result.user?.uid);
    }
    return result.user;
  }

  Future<bool> sendOtpEmail(
    String email,
    String otp,
    String time,
    int duration,
  ) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'email': email,
          'otp': otp,
          'time': time,
          'duration': duration,
        },
      }),
    );
    return response.statusCode == 200;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> _addNewUserToUsersCollection({
    required String? email,
    required String? name,
    required DateTime? createdAt,
    required String? uid,
    required String? profileImageUrl,
  }) async {
    try {
      print(_auth.currentUser);
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'createdAt': createdAt?.toIso8601String(),
        'bio': '',
        'profileImageUrl': profileImageUrl,
        'totalPosts': 0,
        'totalLikes': 0,
        'followersCount': 0,
        'followingCount': 0,
      });
    } on Exception catch (e) {
      print('Error adding user to Firestore: $e');
    }
  }

  Future<void> _saveCurrentUser(String? uid) async {
    final user = await _firestore.collection('users').doc(uid).get();
    final AppUser appUser = AppUser(
      uid: user['uid'],
      name: user['name'],
      email: user['email'],
      fcmToken: user['fcmToken'],
      bio: user['bio'],
      profileImageUrl: user['profileImageUrl'],
      totalPosts: user['totalPosts'],
      totalLikes: user['totalLikes'],
      followersCount: user['followersCount'],
      followingCount: user['followingCount'],
    );
    SessionManager().setUser(appUser);
    print('_saveCurrenyUser: ${SessionManager().currentUser?.uid}');
  }
}
