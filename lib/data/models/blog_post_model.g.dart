// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blog_post_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlogPost _$BlogPostFromJson(Map<String, dynamic> json) => BlogPost(
  postId: json['postId'] as String,
  title: json['title'] as String,
  category: json['category'] as String,
  authorName: json['authorName'] as String,
  uid: json['uid'] as String,
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp,
  ),
  numLikes: (json['numLikes'] as num).toInt(),
  numComments: (json['numComments'] as num).toInt(),
  preview: json['preview'] as String,
);

Map<String, dynamic> _$BlogPostToJson(BlogPost instance) => <String, dynamic>{
  'postId': instance.postId,
  'title': instance.title,
  'category': instance.category,
  'authorName': instance.authorName,
  'uid': instance.uid,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'numLikes': instance.numLikes,
  'numComments': instance.numComments,
  'preview': instance.preview,
};
