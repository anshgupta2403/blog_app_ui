// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment _$CommentFromJson(Map<String, dynamic> json) => Comment(
  json['message'] as String,
  DateTime.parse(json['createAt'] as String),
  json['uid'] as String?,
  json['authorName'] as String?,
);

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
  'message': instance.message,
  'createAt': instance.createAt.toIso8601String(),
  'uid': instance.uid,
  'authorName': instance.authorName,
};
