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
  final String? authorId;

  ToggleLikePost(this.postId, this.userId, this.authorId);
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

class SearchQueryChanged extends HomeEvent {
  final String query;
  final String category;

  SearchQueryChanged(this.query, this.category);
}

class FetchInitialUserBlogs extends HomeEvent {
  final String? uid;
  FetchInitialUserBlogs(this.uid);
}

class FetchMoreUserBlogs extends HomeEvent {
  final String? uid;
  FetchMoreUserBlogs(this.uid);
}

class ApplyFilters extends HomeEvent {
  final String? uid;
  final List<String>? categories;
  final String? sortBy;
  final DateTime? startDate;
  final DateTime? endDate;

  ApplyFilters({
    this.uid,
    this.categories,
    this.sortBy,
    this.startDate,
    this.endDate,
  });
}

class DeleteBlog extends HomeEvent {
  final String postId;

  DeleteBlog(this.postId);
}

class UpdatePost extends HomeEvent {
  final String title;
  final String content;
  final String category;
  final String postId;

  UpdatePost({
    required this.title,
    required this.content,
    required this.category,
    required this.postId,
  });
}

class UpdateProfile extends HomeEvent {
  final String name;
  final String? uid;
  final File? profileImageUrl;

  UpdateProfile(this.name, this.uid, this.profileImageUrl);
}

class SignOut extends HomeEvent {}
