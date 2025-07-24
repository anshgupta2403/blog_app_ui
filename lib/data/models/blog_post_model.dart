import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
part 'blog_post_model.g.dart';

@JsonSerializable(explicitToJson: true)
class BlogPost {
  final String postId;
  final String title;
  final String category;
  final String authorName;
  final String uid;
  @TimestampConverter()
  final DateTime createdAt;
  final int numLikes;
  final int numComments;
  final String preview;

  BlogPost({
    required this.postId,
    required this.title,
    required this.category,
    required this.authorName,
    required this.uid,
    required this.createdAt,
    required this.numLikes,
    required this.numComments,
    required this.preview,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) =>
      _$BlogPostFromJson(json);

  Map<String, dynamic> toJson() => _$BlogPostToJson(this);

  factory BlogPost.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Blog data is null for document ID: ${doc.id}');
    }

    try {
      return BlogPost(
        postId: doc.id,
        title: data['title'] ?? '',
        category: data['category'] ?? '',
        authorName: data['authorName'] ?? '',
        uid: data['uid'] ?? '',
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        numLikes: data['numLikes'] ?? 0,
        numComments: data['numComments'] ?? 0,
        preview: data['preview'] ?? '',
      );
    } catch (e) {
      throw Exception('Error deserializing blog post: $e\nData: $data');
    }
  }

  BlogPost copyWith({
    String? postId,
    String? title,
    String? category,
    String? authorName,
    String? uid,
    DateTime? createdAt,
    int? numLikes,
    int? numComments,
    String? preview,
  }) {
    return BlogPost(
      postId: postId ?? this.postId,
      title: title ?? this.title,
      category: category ?? this.category,
      authorName: authorName ?? this.authorName,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
      numLikes: numLikes ?? this.numLikes,
      numComments: numComments ?? this.numComments,
      preview: preview ?? this.preview,
    );
  }
}

class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) => timestamp.toDate();

  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}
