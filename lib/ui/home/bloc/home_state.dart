part of 'home_bloc.dart';

@immutable
sealed class HomeState {}

final class HomeInitial extends HomeState {}

final class PublishPostRequested extends HomeState {}

final class PublishPostSucess extends HomeState {}

final class PublishPostFailure extends HomeState {
  final String message;

  PublishPostFailure(this.message);
}

final class BlogsLoading extends HomeState {}

final class BlogsLoaded extends HomeState {
  final Map<String, List<BlogPost>> categoryBlogs;

  BlogsLoaded({required this.categoryBlogs});
}

final class BlogsError extends HomeState {
  final String message;

  BlogsError(this.message);
}

final class BlogDetailLoading extends HomeState {}

final class BlogDetailLoadingSuccess extends HomeState {
  final String postContent;

  BlogDetailLoadingSuccess(this.postContent);
}

final class BlogDetailLoadingFailure extends HomeState {
  final String message;

  BlogDetailLoadingFailure(this.message);
}

final class CommentsLoading extends HomeState {}

final class CommentsLoaded extends HomeState {
  final List<Comment> comments;

  CommentsLoaded({required this.comments});
}

final class CommentsError extends HomeState {
  final String message;

  CommentsError(this.message);
}

final class AddCommentRequested extends HomeState {}

final class AddCommentSuccess extends HomeState {}

final class AddCommentFailure extends HomeState {
  final String message;

  AddCommentFailure(this.message);
}

final class CommentAddedLocally extends HomeState {
  final Comment newComment;

  CommentAddedLocally(this.newComment);
}

final class PostInitial extends HomeState {}

final class PostLikeUpdated extends HomeState {
  final bool isLiked;

  PostLikeUpdated(this.isLiked);
}

final class FollowAuthorRequested extends HomeState {}

final class FollowAuthorSuccess extends HomeState {}

final class FollowAuthorFailure extends HomeState {
  final String message;

  FollowAuthorFailure(this.message);
}

final class UnfollowAuthorRequested extends HomeState {}

final class UnfollowAuthorSuccess extends HomeState {}

final class UnfollowAuthorFailure extends HomeState {
  final String message;

  UnfollowAuthorFailure(this.message);
}

final class FollowStatusRequested extends HomeState {}

final class FollowStatusSuccess extends HomeState {
  final bool isFollowing;
  FollowStatusSuccess(this.isFollowing);
}

final class FollowStatusFailure extends HomeState {
  final String message;
  FollowStatusFailure(this.message);
}
