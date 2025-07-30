import 'dart:async';
import 'dart:io';

import 'package:blog_app/data/models/app_notification_model.dart';
import 'package:blog_app/data/models/app_user_model.dart';
import 'package:blog_app/data/models/blog_post_model.dart';
import 'package:blog_app/data/models/comment_model.dart';
import 'package:blog_app/data/repositories/blog_repository.dart';
import 'package:blog_app/ui/core/utils/session_manager_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final BlogRepository _blogRepository;
  DocumentSnapshot? _lastDoc;
  List<BlogPost> _blogs = [];
  StreamSubscription<List<AppNotification>>? _subscription;
  List<AppNotification> _notifications = [];

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
    on<SearchQueryChanged>(
      _onQueryChanged,
      transformer: debounce(const Duration(milliseconds: 500)),
    );
    on<FetchInitialUserBlogs>(_onLoadUserBlogs);
    on<FetchMoreUserBlogs>(_onLoadMore);
    on<ApplyFilters>(_onApplyFilters);
    on<DeleteBlog>(_onDeleteBlog);
    on<UpdatePost>(_onUpdatePost);
    on<UpdateProfile>(_onUpdateProfile);
    on<SignOut>(_onSignOut);
    on<LoadNotifications>(_onLoad);
    on<NewNotificationReceived>(_onNew);
    on<DeleteNotification>(_onDeleteNotification);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<LoadBlogSummary>(_onLoadBlogSummary);
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
    emit(BlogsLoading());
    try {
      final blogs = await _blogRepository.getBlogsByCategory(
        category: event.category,
      );
      emit(BlogsLoaded(categoryBlogs: blogs));
    } catch (e) {
      emit(BlogsError(e.toString()));
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
        await _blogRepository.toggleLike(
          event.postId,
          event.userId!,
          event.authorId!,
        );
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

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<HomeState> emit,
  ) async {
    emit(SearchLoading());

    try {
      final results = await _blogRepository.searchBlogsByTitle(
        event.query,
        event.category,
      );
      emit(BlogsLoaded(categoryBlogs: results));
    } catch (e) {
      emit(BlogsError('Something went wrong'));
    }
  }

  EventTransformer<T> debounce<T>(Duration duration) {
    return (events, mapper) => events.debounceTime(duration).flatMap(mapper);
  }

  Future<void> _onLoadUserBlogs(
    FetchInitialUserBlogs event,
    Emitter<HomeState> emit,
  ) async {
    emit(ProfileBlogLoading());
    try {
      final blogs = await _blogRepository.getUserBlogs(
        uid: event.uid,
        lastDoc: _lastDoc,
        limit: 10,
      );

      _blogs = blogs.blogs;

      emit(
        ProfileBlogLoaded(
          blogs: [..._blogs, ...blogs.blogs],
          hasMore: blogs.hasMore,
          lastDoc: blogs.lastDoc,
        ),
      );
    } catch (e) {
      emit(ProfileBlogError(e.toString()));
    }
  }

  Future<void> _onLoadMore(
    FetchMoreUserBlogs event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileBlogLoaded || !currentState.hasMore) return;

    try {
      final result = await _blogRepository.fetchUserBlogs(
        uid: event.uid!,
        startAfterDoc: currentState.lastDoc,
        limit: 10,
        categories: currentState.categories,
        sortBy: currentState.sortBy,
        startDate: currentState.startDate,
        endDate: currentState.endDate,
      );

      emit(
        ProfileBlogLoaded(
          blogs: [...currentState.blogs, ...result.blogs],
          hasMore: result.hasMore,
          lastDoc: result.lastDoc,
          categories: currentState.categories,
          sortBy: currentState.sortBy,
          startDate: currentState.startDate,
          endDate: currentState.endDate,
        ),
      );
    } catch (e) {
      emit(ProfileBlogError(e.toString()));
    }
  }

  Future<void> _onApplyFilters(
    ApplyFilters event,
    Emitter<HomeState> emit,
  ) async {
    emit(BlogsLoading());

    try {
      final result = await _blogRepository.fetchUserBlogs(
        uid: event.uid,
        limit: 10,
        categories: event.categories,
        sortBy: event.sortBy,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(
        ProfileBlogLoaded(
          blogs: result.blogs,
          hasMore: result.hasMore,
          lastDoc: result.lastDoc,
          categories: event.categories,
          sortBy: event.sortBy,
          startDate: event.startDate,
          endDate: event.endDate,
        ),
      );
    } catch (e) {
      emit(ProfileBlogError(e.toString()));
    }
  }

  Future<void> _onDeleteBlog(DeleteBlog event, Emitter<HomeState> emit) async {
    emit(DeleteBlogRequested());
    try {
      await _blogRepository.deleteBlog(event.postId);

      emit(DeleteBlogSucess());
    } catch (e) {
      emit(DeleteBlogError('Failed to delete blog'));
    }
  }

  Future<void> _onUpdatePost(UpdatePost event, Emitter<HomeState> emit) async {
    emit(UpdatePostRequested());
    try {
      await _blogRepository.updatePost(
        title: event.title,
        category: event.category,
        content: event.content,
        postId: event.postId,
      );
      emit(UpdatePostSuccess());
    } catch (e) {
      emit(UpdatePostFailure(e.toString()));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<HomeState> emit,
  ) async {
    emit(UpdateProfileRequested());
    try {
      await _blogRepository.updateProfile(
        name: event.name,
        uid: event.uid,
        profileImageUrl: event.profileImageUrl,
      );
      emit(UpdateProfileSuccess());
    } catch (e) {
      emit(UpdateProfileFailure('Failed to update profile'));
    }
  }

  Future<void> _onSignOut(SignOut event, Emitter<HomeState> emit) async {
    emit(SignOutRequested());
    try {
      await Future.delayed(const Duration(seconds: 2));
      await _blogRepository.signout();
      SessionManager().setUser(AppUser());
      emit(SignOutSuccess());
    } catch (e) {
      emit(SignOutFailure('Sign Out Failed'));
    }
  }

  Future<void> _onLoad(LoadNotifications event, Emitter<HomeState> emit) async {
    emit(NotificationLoading());

    try {
      await _subscription?.cancel(); // Cancel previous listener if any

      // Replace manual `listen()` with emit.forEach
      final stream = _blogRepository.getNotifications(event.uid!);

      await emit.forEach<List<AppNotification>>(
        stream,
        onData: (notifs) {
          _notifications = notifs;
          final unreadCount = notifs.where((n) => !n.isRead).length;

          return NotificationLoaded(
            notifications: _notifications,
            unreadCount: unreadCount,
          );
        },
        onError: (e, _) {
          debugPrint(e.toString());
          return NotificationError('Failed to load notifications');
        },
      );
    } catch (e) {
      debugPrint(e.toString());
      emit(NotificationError('Failed to load notifications'));
    }
  }

  void _onNew(NewNotificationReceived event, Emitter<HomeState> emit) {
    if (state is NotificationLoaded) {
      final current = (state as NotificationLoaded).notifications;
      final updated = [event.notification, ...current];
      final unreadCount = updated.where((n) => !n.isRead).length;

      emit(
        NotificationLoaded(notifications: updated, unreadCount: unreadCount),
      );
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await _blogRepository.deleteNotification(
        event.notificationId,
        event.userId!,
      );
    } catch (_) {
      emit(NotificationError('Failed to delete notification'));
    }
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await _blogRepository.markAsRead(event.notificationId, event.userId!);
    } catch (_) {
      emit(NotificationError('Failed to mark as read'));
    }
  }

  Future<void> _onLoadBlogSummary(
    LoadBlogSummary event,
    Emitter<HomeState> emit,
  ) async {
    emit(LoadBlogSummaryRequested());
    try {
      final blogPost = await _blogRepository.getBlogSummary(event.postId);
      emit(LoadBlogSummarySuccess(blogPost));
    } catch (e) {
      emit(LoadBlogSummaryfailure('Error loading blog.'));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
