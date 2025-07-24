import 'package:blog_app/data/models/blog_post_model.dart';
import 'package:blog_app/data/models/comment_model.dart';
import 'package:blog_app/data/repositories/blog_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final BlogRepository _blogRepository;
  final Map<String, List<BlogPost>> _categoryBlogs = {};
  final List<BlogPost> _blogs = [];
  List<BlogPost> get blogs => _blogs;
  HomeBloc(this._blogRepository) : super(HomeInitial()) {
    on<PublishPost>(_onPublishPost);
    on<LoadBlogs>(_onLoadBlogs);
    on<LoadBlogDetails>(_onLoadBlogDetail);
    on<LoadComments>(_onLoadComments);
    on<ToggleLikePost>(_onToggleLike);
    on<AddComment>(_onAddComment);
    on<CheckIfPostLiked>(_onCheckLiked);
    on<FollowAuthor>(_onFollowAuthor);
    on<UnfollowAuthor>(_onUnfollowAuthor);
    on<CheckFollowStatus>(_onCheckFollowStatus);
  }

  Future<void> _onPublishPost(
    PublishPost event,
    Emitter<HomeState> emit,
  ) async {
    emit(PublishPostRequested());
    try {
      await _blogRepository.publishPost(
        title: event.title,
        content: event.content,
        category: event.category,
        createAt: DateTime.now(),
      );
      emit(PublishPostSucess());
    } catch (e) {
      emit(PublishPostFailure(e.toString()));
    }
  }

  Future<void> _onLoadBlogs(LoadBlogs event, Emitter<HomeState> emit) async {
    final category = event.category;

    if (event.isRefresh || !_categoryBlogs.containsKey(category)) {
      emit(BlogsLoading());
      try {
        final blogs = await _blogRepository.getBlogsByCategory(
          category: category,
        );
        _categoryBlogs[category] = blogs;
        emit(BlogsLoaded(categoryBlogs: {..._categoryBlogs}));
      } catch (e) {
        emit(BlogsError(e.toString()));
      }
    } else {
      // Already loaded, emit again
      emit(BlogsLoaded(categoryBlogs: {..._categoryBlogs}));
    }
  }

  Future<void> _onLoadBlogDetail(
    LoadBlogDetails event,
    Emitter<HomeState> emit,
  ) async {
    emit(BlogDetailLoading());
    try {
      final blog = await _blogRepository.getBlogById(event.postId);
      emit(BlogDetailLoadingSuccess(blog));
    } catch (e) {
      emit(BlogDetailLoadingFailure(e.toString()));
    }
  }

  Future<void> _onLoadComments(
    LoadComments event,
    Emitter<HomeState> emit,
  ) async {
    emit(CommentsLoading());
    try {
      final comments = await _blogRepository.fetchComments(event.postId);
      emit(CommentsLoaded(comments: comments));
    } catch (e) {
      emit(CommentsError(e.toString()));
    }
  }

  Future<void> _onAddComment(AddComment event, Emitter<HomeState> emit) async {
    emit(AddCommentRequested());
    try {
      await _blogRepository.addComment(event.postId, event.comment);
      // Emit the new comment locally
      emit(CommentAddedLocally(event.comment));

      // Reload the full comments from Firestore
      add(LoadComments(event.postId));
      emit(AddCommentSuccess());
    } catch (e) {
      emit(AddCommentFailure(e.toString()));
    }
  }

  Future<void> _onToggleLike(
    ToggleLikePost event,
    Emitter<HomeState> emit,
  ) async {
    try {
      if (event.userId != null) {
        await _blogRepository.toggleLike(event.postId, event.userId!);
        final isLiked = await _blogRepository.isPostLiked(
          event.postId,
          event.userId!,
        );
        emit(PostLikeUpdated(isLiked));
      }
    } catch (e) {
      debugPrint('Like Failed:  ${e.toString()}');
    }
  }

  Future<void> _onCheckLiked(
    CheckIfPostLiked event,
    Emitter<HomeState> emit,
  ) async {
    final isLiked = await _blogRepository.isPostLiked(
      event.postId,
      event.userId,
    );
    emit(PostLikeUpdated(isLiked));
  }

  Future<void> _onFollowAuthor(
    FollowAuthor event,
    Emitter<HomeState> emit,
  ) async {
    emit(FollowAuthorRequested());
    try {
      debugPrint('Follow Author: ${event.currentUserId} ${event.targetUserId}');
      await _blogRepository.followAuthor(
        event.currentUserId!,
        event.targetUserId!,
      );
      emit(FollowAuthorSuccess());
    } catch (e) {
      emit(FollowAuthorFailure('Follow author failed'));
    }
  }

  Future<void> _onUnfollowAuthor(
    UnfollowAuthor event,
    Emitter<HomeState> emit,
  ) async {
    emit(UnfollowAuthorRequested());
    try {
      await _blogRepository.unfollowAuthor(
        event.currentUserId!,
        event.targetUserId!,
      );
      emit(UnfollowAuthorSuccess());
    } catch (e) {
      emit(UnfollowAuthorFailure('Unfollow author failed'));
    }
  }

  Future<void> _onCheckFollowStatus(
    CheckFollowStatus event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final isFollowing = await _blogRepository.isFollowing(
        event.currentUserId,
        event.authorId,
      );
      emit(FollowStatusSuccess(isFollowing));
    } catch (e) {
      emit(FollowStatusFailure('Failed to check follow status'));
    }
  }
}
