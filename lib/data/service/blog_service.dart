import 'package:blog_app/data/models/blog_post_model.dart';
import 'package:blog_app/data/models/comment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DocumentSnapshot? _lastVisible;

  Future<void> publishPost({
    required String title,
    required String content,
    required String category,
    required DateTime createdAt,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final authorDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final authorName = authorDoc['name'] ?? 'Anonymous';

    final postRef = FirebaseFirestore.instance
        .collection('posts_summary')
        .doc();

    await FirebaseFirestore.instance.runTransaction((txn) async {
      txn.set(postRef, {
        'title': title,
        'category': category,
        'authorName': authorName,
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'numLikes': 0,
        'numComments': 0,
        'preview': content.length > 100 ? content.substring(0, 100) : content,
      });

      txn.set(
        FirebaseFirestore.instance.collection('posts_content').doc(postRef.id),
        {'postId': postRef.id, 'content': content},
      );
    });
  }

  Future<List<BlogPost>> getBlogsByCategory({
    required String category,
    required int limit,
    required bool isRefresh,
  }) async {
    if (isRefresh) _lastVisible = null;

    Query query = _firestore
        .collection('posts_summary')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (_lastVisible != null) {
      query = query.startAfterDocument(_lastVisible!);
    }

    final snapshot = await query.get();
    if (snapshot.docs.isNotEmpty) {
      _lastVisible = snapshot.docs.last;
    }
    return snapshot.docs.map((doc) => BlogPost.fromSnapshot(doc)).toList();
  }

  void resetPagination() {
    _lastVisible = null;
  }

  //Get blog details by id
  Future<DocumentSnapshot> getBlogById(String postId) async {
    return await _firestore.collection('posts_content').doc(postId).get();
  }

  //Like post
  Future<void> likePost(String postId, String uid) async {
    final likeDoc = _firestore
        .collection('posts_summary')
        .doc(postId)
        .collection('likes')
        .doc(uid);

    final postDoc = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final likeSnapshot = await transaction.get(likeDoc);
      if (!likeSnapshot.exists) {
        transaction.set(likeDoc, {'likedAt': FieldValue.serverTimestamp()});
        transaction.update(postDoc, {'numLikes': FieldValue.increment(1)});
      }
    });
  }

  //Unlike post
  Future<void> unlikePost(String postId, String uid) async {
    final likeDoc = _firestore
        .collection('posts_summary')
        .doc(postId)
        .collection('likes')
        .doc(uid);

    final postDoc = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final likeSnapshot = await transaction.get(likeDoc);
      if (likeSnapshot.exists) {
        transaction.delete(likeDoc);
        transaction.update(postDoc, {'numLikes': FieldValue.increment(-1)});
      }
    });
  }

  //Get comments on post by id
  Future<List<Comment>> fetchComments(
    String postId, {
    DocumentSnapshot? lastDoc,
  }) async {
    Query query = _firestore
        .collection('posts_summary')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .limit(10);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Comment.fromSnapshot(doc)).toList();
  }

  Future<void> addComment(String postId, Comment comment) async {
    final postRef = _firestore.collection('posts_summary').doc(postId);
    final commentRef = postRef
        .collection('comments')
        .doc(); // auto-generated ID

    final commentData = {
      'commentId': commentRef.id,
      'userId': comment.uid,
      'userName': comment.authorName,
      'commentText': comment.message,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore.runTransaction((transaction) async {
        // Check if the post exists
        final postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) {
          throw Exception('Post does not exist');
        }

        // Add the comment
        transaction.set(commentRef, commentData);

        // Atomically increment the comment count
        transaction.update(postRef, {'numComments': FieldValue.increment(1)});
      });
    } catch (e) {
      throw Exception('Failed to add comment atomically: $e');
    }
  }

  //Like/Unlike the post
  Future<void> toggleLikePost(String postId, String userId) async {
    final postRef = _firestore.collection('posts_summary').doc(postId);
    final likeRef = postRef.collection('likes').doc(userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final likeSnapshot = await transaction.get(likeRef);
      final postSnapshot = await transaction.get(postRef);

      int currentLikes = postSnapshot.data()?['likesCount'] ?? 0;

      if (likeSnapshot.exists) {
        // User already liked, so unlike
        transaction.delete(likeRef);
        transaction.update(postRef, {
          'numLikes': currentLikes > 0 ? currentLikes - 1 : 0,
        });
      } else {
        // User hasn't liked, so add like
        transaction.set(likeRef, {'likedAt': FieldValue.serverTimestamp()});
        transaction.update(postRef, {'numLikes': currentLikes + 1});
      }
    });
  }

  // Check if post already liked
  Future<bool> isPostLiked(String postId, String? userId) async {
    final doc = await _firestore
        .collection('posts_summary')
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .get();
    return doc.exists;
  }

  Future<void> followAuthor(String followerId, String authorId) async {
    final batch = _firestore.batch();

    final followerRef = _firestore
        .collection('users')
        .doc(authorId)
        .collection('followers')
        .doc(followerId);

    final followingRef = _firestore
        .collection('users')
        .doc(followerId)
        .collection('following')
        .doc(authorId);

    final timestamp = FieldValue.serverTimestamp();

    // Add currentUserId to targetUserId's followers
    batch.set(followerRef, {'followerId': followerId, 'followedAt': timestamp});

    // Add targetUserId to currentUserId's following
    batch.set(followingRef, {'authorId': authorId, 'followedAt': timestamp});

    await batch.commit();
  }

  Future<void> unfollowAuthor(String followerId, String authorId) async {
    final batch = _firestore.batch();

    final followingRef = _firestore
        .collection('users')
        .doc(followerId)
        .collection('following')
        .doc(authorId);
    final followersRef = _firestore
        .collection('users')
        .doc(authorId)
        .collection('followers')
        .doc(followerId);

    batch.delete(followingRef);
    batch.delete(followersRef);

    await batch.commit();
  }

  Future<bool> isFollowing({
    required String currentUserId,
    required String authorId,
  }) async {
    final doc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(authorId)
        .get();
    return doc.exists;
  }

  bool get hasMore => _lastVisible != null;
}
