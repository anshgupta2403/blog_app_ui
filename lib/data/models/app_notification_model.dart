import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String postId;
  final DateTime createdAt;
  final bool isRead;
  final String authorName;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.postId,
    required this.createdAt,
    required this.isRead,
    required this.authorName,
  });

  factory AppNotification.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['preview'] ?? '',
      postId: data['postId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      authorName: data['authorName'] ?? '',
    );
  }
}
