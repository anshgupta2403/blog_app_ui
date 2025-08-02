import 'dart:io';

import 'package:blog_app/data/models/app_notification_model.dart';
import 'package:blog_app/data/models/blog_post_model.dart';
import 'package:blog_app/data/models/blog_result_model.dart';
import 'package:blog_app/data/models/comment_model.dart';
import 'package:blog_app/data/service/blog_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BlogRepository {
  final BlogService _blogService;

  BlogRepository(this._blogService);

  Future<void> publishPost({
    required String title,
    required String content,
    required String category,
    required DateTime createAt,
  }) async {
    await _blogService.publishPost(
      title: title,
      content: content,
      category: category,
      createdAt: createAt,
    );
  }

  Future<List<DocumentSnapshot>> getBlogsByCategory({
    required String category,
    int limit = 10,
    bool isRefresh = false,
    DocumentSnapshot? lastDoc,
  }) {
    return _blogService.getBlogsByCategory(
      category: category,
      limit: limit,
      isRefresh: isRefresh,
      lastDoc: lastDoc,
    );
  }

  void resetPagination() {
    _blogService.resetPagination();
  }

  Future<String> getBlogById(String postId) async {
    final docSnapshot = await _blogService.getBlogById(postId);

    if (!docSnapshot.exists) {
      throw Exception('Blog not found');
    }

    final data = docSnapshot.get('content');

    if (data == null) {
      throw Exception('Blog data is null');
    }

    return data;
  }

  Future<List<Comment>> fetchComments(String postId) async {
    return await _blogService.fetchComments(postId);
  }

  Future<void> addComment(String postId, Comment comment) {
    return _blogService.addComment(postId, comment);
  }

  Future<void> toggleLike(String postId, String userId, String authorId) async {
    return await _blogService.toggleLikePost(postId, userId, authorId);
  }

  Future<bool> isPostLiked(String postId, String? userId) {
    return _blogService.isPostLiked(postId, userId);
  }

  Future<void> followAuthor(String followerId, String authorId) {
    return _blogService.followAuthor(followerId, authorId);
  }

  Future<void> unfollowAuthor(String followerId, String authorId) {
    return _blogService.unfollowAuthor(followerId, authorId);
  }

  Future<bool> isFollowing(String currentUserId, String authorId) {
    return _blogService.isFollowing(
      currentUserId: currentUserId,
      authorId: authorId,
    );
  }

  Future<List<DocumentSnapshot>> searchBlogsByTitle({
    required String searchQuery,
    required String category,
    required int limit,
    DocumentSnapshot? lastDoc,
  }) {
    return _blogService.searchBlogsByTitle(
      searchQuery: searchQuery,
      category: category,
      limit: limit,
      lastDoc: lastDoc,
    );
  }

  Future<BlogQueryResult> getUserBlogs({
    required String? uid,
    DocumentSnapshot? lastDoc,
    int? limit,
  }) {
    return _blogService.getUserBlogs(uid: uid, lastDoc: lastDoc, limit: limit);
  }

  Future<BlogQueryResult> fetchUserBlogs({
    required String? uid,
    int limit = 10,
    DocumentSnapshot? startAfterDoc,
    List<String>? categories,
    String? sortBy,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _blogService.fetchUserBlogs(
      uid: uid,
      limit: limit,
      startAfterDoc: startAfterDoc,
      categories: categories,
      sortBy: sortBy,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<void> deleteBlog(String postId) {
    return _blogService.deleteBlog(postId);
  }

  Future<void> updatePost({
    required String title,
    required String category,
    required String content,
    required String postId,
  }) async {
    await _blogService.updatePost(
      title: title,
      category: category,
      content: content,
      postId: postId,
    );
  }

  Future<void> updateProfile({
    required String name,
    required String? uid,
    required File? profileImageUrl,
  }) async {
    await _blogService.updateProfile(
      name: name,
      uid: uid,
      profileImageFile: profileImageUrl,
    );
  }

  Stream<List<AppNotification>> getNotifications(String userId) {
    return _blogService.fetchNotifications(userId);
  }

  Future<void> markAsRead(String notificationId, String userId) {
    return _blogService.markAsRead(notificationId, userId);
  }

  Future<void> deleteNotification(String notificationId, String userId) {
    return _blogService.deleteNotification(notificationId, userId);
  }

  Future<void> signout() async {
    await _blogService.signout();
  }

  Future<BlogPost> getBlogSummary(String postId) {
    return _blogService.getBlogSummary(postId);
  }

  Future<void> getCurrentUser(String uid) async {
    await _blogService.getCurrentUser(uid);
  }
}
