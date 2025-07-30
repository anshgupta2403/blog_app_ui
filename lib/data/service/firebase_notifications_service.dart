import 'dart:convert';
import 'package:blog_app/data/models/blog_post_model.dart';
import 'package:blog_app/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class FirebaseNotificationsService {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static final AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important notifications',
    importance: Importance.high,
  );

  /// Call this once in main()
  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
    );

    final fcmToken = await _firebaseMessaging.getToken();
    await _saveUserFcmToken(fcmToken);

    await _initLocalNotifications();
    await _initPushNotifications();
  }

  Future<void> _saveUserFcmToken(String? token) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null && token != null) {
      await _firestore.collection('users').doc(uid).update({'fcmToken': token});
    }
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@drawable/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null) {
          try {
            final data = jsonDecode(payload);
            _navigateToPostFromData(data);
          } catch (e) {
            debugPrint('Error decoding local notification payload: $e');
          }
        }
      },
    );

    final platform = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await platform?.createNotificationChannel(_channel);
  }

  Future<void> _initPushNotifications() async {
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      handleMessage(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null && message.data.isNotEmpty) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: '@drawable/ic_launcher',
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });
  }

  /// Static method: invoked by background handler
  static Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
    debugPrint('Background message received: ${message.messageId}');
  }

  /// Handle notification tap or initial message
  void handleMessage(RemoteMessage message) {
    if (message.data.isNotEmpty) {
      _navigateToPostFromData(message.data);
    }
  }

  /// Extract and navigate to blog post from data
  void _navigateToPostFromData(Map<String, dynamic> data) {
    final postId = data['postId'];
    final summaryJson = data['summary'];

    if (postId == null || summaryJson == null) return;

    try {
      final decoded = summaryJson is String
          ? jsonDecode(summaryJson)
          : summaryJson;
      final blog = BlogPost(
        title: decoded['title'],
        authorName: decoded['authorName'],
        category: decoded['category'],
        createdAt: decoded['createdAt'],
        numComments: decoded['numComments'],
        numLikes: decoded['numLikes'],
        postId: decoded['postId'],
        preview: decoded['preview'],
        uid: decoded['uid'],
      );

      GoRouter.of(
        navigatorKey.currentContext!,
      ).go('/blog-details', extra: {'postId': postId, 'summary': blog});
    } catch (e) {
      debugPrint('Error navigating from data: $e');
    }
  }
}
