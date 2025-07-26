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
  final List<BlogPost> categoryBlogs;

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

final class SearchInitial extends HomeState {}

final class SearchLoading extends HomeState {}

final class SearchLoaded extends HomeState {
  final List<BlogPost> categoryBlogs; // replace with your model
  SearchLoaded(this.categoryBlogs);
}

final class SearchError extends HomeState {
  final String message;
  SearchError(this.message);
}

class ProfileBlogLoading extends HomeState {}

class ProfileBlogLoaded extends HomeState {
  final List<BlogPost> blogs;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;
  final List<String>? categories;
  final String? sortBy;
  final DateTime? startDate;
  final DateTime? endDate;

  ProfileBlogLoaded({
    required this.blogs,
    required this.hasMore,
    required this.lastDoc,
    this.categories,
    this.sortBy,
    this.startDate,
    this.endDate,
  });
}

class ProfileBlogError extends HomeState {
  final String message;
  ProfileBlogError(this.message);
}

class DeleteBlogRequested extends HomeState {}

class DeleteBlogSucess extends HomeState {}

class DeleteBlogError extends HomeState {
  final String message;
  DeleteBlogError(this.message);
}

class UpdatePostRequested extends HomeState {}

class UpdatePostSuccess extends HomeState {}

class UpdatePostFailure extends HomeState {
  final String message;
  UpdatePostFailure(this.message);
}

class UpdateProfileRequested extends HomeState {}

class UpdateProfileSuccess extends HomeState {}

class UpdateProfileFailure extends HomeState {
  final String message;
  UpdateProfileFailure(this.message);
}

class SignOutRequested extends HomeState {}

class SignOutSuccess extends HomeState {}

class SignOutFailure extends HomeState {
  final String message;
  SignOutFailure(this.message);
}
