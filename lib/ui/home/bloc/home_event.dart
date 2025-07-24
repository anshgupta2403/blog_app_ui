part of 'home_bloc.dart';

@immutable
sealed class HomeEvent {}

class PublishPost extends HomeEvent {
  final String title;
  final String content;
  final String category;

  PublishPost({
    required this.title,
    required this.content,
    required this.category,
  });
}

class LoadBlogs extends HomeEvent {
  final String category;
  final bool isRefresh;

  LoadBlogs({required this.category, this.isRefresh = false});
}

class LoadBlogDetails extends HomeEvent {
  final String postId;
  LoadBlogDetails(this.postId);
}

class AddComment extends HomeEvent {
  final String postId;
  final Comment comment;

  AddComment(this.postId, this.comment);
}

final class LoadComments extends HomeEvent {
  final String postId;

  LoadComments(this.postId);
}

class ToggleLikePost extends HomeEvent {
  final String postId;
  final String? userId;

  ToggleLikePost(this.postId, this.userId);
}

class CheckIfPostLiked extends HomeEvent {
  final String postId;
  final String? userId;

  CheckIfPostLiked(this.postId, this.userId);
}

class FollowAuthor extends HomeEvent {
  final String? currentUserId;
  final String? targetUserId;

  FollowAuthor(this.currentUserId, this.targetUserId);
}

class UnfollowAuthor extends HomeEvent {
  final String? currentUserId;
  final String? targetUserId;

  UnfollowAuthor(this.currentUserId, this.targetUserId);
}

class CheckFollowStatus extends HomeEvent {
  final String currentUserId;
  final String authorId;

  CheckFollowStatus(this.currentUserId, this.authorId);
}
