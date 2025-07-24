import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'comment_model.g.dart';

@JsonSerializable()
class Comment {
  final String message;
  final DateTime createAt;
  final String? uid;
  final String? authorName;

  Comment(this.message, this.createAt, this.uid, this.authorName);

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);

  Map<String, dynamic> toJson() => _$CommentToJson(this);

  factory Comment.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Blog data is null for document ID: ${doc.id}');
    }

    try {
      final date =
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      return Comment(
        data['commentText'],
        date,
        data['userId'],
        data['userName'],
      );
    } catch (e) {
      throw Exception('Error deserializing comment post: $e\nData: $data');
    }
  }
}
