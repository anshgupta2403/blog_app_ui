import 'package:blog_app/data/models/blog_post_model.dart';
import 'package:blog_app/data/models/comment_model.dart';
import 'package:blog_app/data/service/blog_service.dart';

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

  Future<List<BlogPost>> getBlogsByCategory({
    required String category,
    int limit = 10,
    bool isRefresh = false,
  }) {
    return _blogService.getBlogsByCategory(
      category: category,
      limit: limit,
      isRefresh: isRefresh,
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

  Future<void> toggleLike(String postId, String userId) async {
    return await _blogService.toggleLikePost(postId, userId);
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
}
