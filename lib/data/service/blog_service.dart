import 'dart:io';

import 'package:blog_app/data/models/app_user_model.dart';
import 'package:blog_app/data/models/blog_post_model.dart';
import 'package:blog_app/data/models/blog_result_model.dart';
import 'package:blog_app/data/models/comment_model.dart';
import 'package:blog_app/ui/core/utils/session_manager_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class BlogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

    final usersRef = _firestore.collection('users').doc(user.uid);
    int? totalPosts = SessionManager().currentUser?.totalPosts;

    await _firestore.runTransaction((txn) async {
      txn.set(postRef, {
        'title': title,
        'category': category,
        'authorName': authorName,
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'numLikes': 0,
        'numComments': 0,
        'preview': content.length > 100 ? content.substring(0, 100) : content,
        'titleLowercase': title.toLowerCase(),
      });

      txn.set(
        FirebaseFirestore.instance.collection('posts_content').doc(postRef.id),
        {'postId': postRef.id, 'content': content},
      );

      txn.set(usersRef, {'totalPosts': totalPosts! + 1});
    });
  }

  Future<List<BlogPost>> getBlogsByCategory({
    required String category,
    required int limit,
    required bool isRefresh,
  }) async {
    Query query = _firestore
        .collection('posts_summary')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    final snapshot = await query.get();

    return snapshot.docs.map((doc) => BlogPost.fromSnapshot(doc)).toList();
  }

  void resetPagination() {
    _lastVisible = null;
  }

  //Get blog details by id
  Future<DocumentSnapshot> getBlogById(String postId) async {
    return await _firestore.collection('posts_content').doc(postId).get();
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
  Future<void> toggleLikePost(
    String postId,
    String userId,
    String authorId,
  ) async {
    final postRef = _firestore.collection('posts_summary').doc(postId);
    final likeRef = postRef.collection('likes').doc(userId);
    final userRef = _firestore.collection('users').doc(authorId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final likeSnapshot = await transaction.get(likeRef);
      final postSnapshot = await transaction.get(postRef);
      final userSnapshot = await transaction.get(userRef);

      int currentLikes = postSnapshot.data()?['likesCount'] ?? 0;
      int totalLikes = userSnapshot.data()?['totalLikes'] ?? 0;

      if (likeSnapshot.exists) {
        // User already liked, so unlike
        transaction.delete(likeRef);
        transaction.update(postRef, {
          'numLikes': currentLikes > 0 ? currentLikes - 1 : 0,
        });
        transaction.update(userRef, {
          'totalLikes': totalLikes > 0 ? totalLikes - 1 : 0,
        });
      } else {
        // User hasn't liked, so add like
        transaction.set(likeRef, {'likedAt': FieldValue.serverTimestamp()});
        transaction.update(postRef, {'numLikes': currentLikes + 1});
        transaction.update(userRef, {'totalLikes': totalLikes + 1});
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

    final usersRef = _firestore.collection('users').doc(authorId);
    final authorRef = _firestore.collection('users').doc(followerId);
    int? totalFollowers = SessionManager().currentUser?.followersCount;
    int? totalFollowing = SessionManager().currentUser?.followingCount;

    final followerRef = usersRef.collection('followers').doc(followerId);

    final followingRef = authorRef.collection('following').doc(authorId);

    final timestamp = FieldValue.serverTimestamp();

    // Add currentUserId to targetUserId's followers
    batch.set(followerRef, {'followerId': followerId, 'followedAt': timestamp});

    // Add targetUserId to currentUserId's following
    batch.set(followingRef, {'authorId': authorId, 'followedAt': timestamp});

    batch.set(usersRef, {'followersCount': totalFollowers! + 1});
    batch.set(authorRef, {'followingCount': totalFollowing! + 1});

    await batch.commit();
  }

  Future<void> unfollowAuthor(String followerId, String authorId) async {
    final batch = _firestore.batch();

    final usersRef = _firestore.collection('users').doc(authorId);
    final authorRef = _firestore.collection('users').doc(followerId);
    int? totalFollowers = SessionManager().currentUser?.followersCount;
    int? totalFollowing = SessionManager().currentUser?.followingCount;

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

    batch.set(usersRef, {'followersCount': totalFollowers! - 1});
    batch.set(authorRef, {'followingCount': totalFollowing! - 1});

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

  Future<List<BlogPost>> searchBlogsByTitle(
    String query,
    String category,
  ) async {
    final snapshot = await _firestore
        .collection('posts_summary')
        .where('category', isEqualTo: category)
        .where('titleLowercase', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('titleLowercase', isLessThan: '${query.toLowerCase()}\uf8ff')
        .orderBy('titleLowercase')
        .get();

    return snapshot.docs.map((doc) => BlogPost.fromSnapshot(doc)).toList();
  }

  Future<BlogQueryResult> getUserBlogs({
    required String? uid,
    DocumentSnapshot? lastDoc,
    int? limit = 10,
  }) async {
    Query query = _firestore
        .collection('posts_summary')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit!);

    final snapshot = await query.get();
    final blogs = snapshot.docs
        .map((doc) => BlogPost.fromSnapshot(doc))
        .toList();

    return BlogQueryResult(
      blogs: blogs,
      lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: snapshot.docs.length == limit,
    );
  }

  Future<BlogQueryResult> fetchUserBlogs({
    required String? uid,
    int limit = 10,
    DocumentSnapshot? startAfterDoc,
    List<String>? categories,
    String? sortBy,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _firestore
        .collection('posts_summary')
        .where('uid', isEqualTo: uid);

    if (categories != null && categories.isNotEmpty) {
      query = query.where('category', whereIn: categories);
    }

    if (startDate != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      query = query.where(
        'createdAt',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    if (sortBy == 'Popular') {
      query = query.orderBy('numLikes', descending: true);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    final snapshot = await query.limit(limit).get();

    final blogs = snapshot.docs
        .map((doc) => BlogPost.fromSnapshot(doc))
        .toList();

    return BlogQueryResult(
      blogs: blogs,
      lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: snapshot.docs.length == limit,
    );
  }

  Future<void> deleteBlog(String postId) async {
    final docRef = _firestore.collection('posts_summary').doc(postId);
    await docRef.delete();
  }

  Future<void> updatePost({
    required String title,
    required String category,
    required String content,
    required String postId,
  }) async {
    final postRef = _firestore.collection('posts_summary').doc(postId);
    await _firestore.runTransaction((txn) async {
      txn.update(postRef, {'title': title, 'category': category});

      txn.update(_firestore.collection('posts_content').doc(postId), {
        'content': content,
      });
    });
  }

  Future<void> updateProfile({
    required String name,
    required String? uid,
    required File? profileImageUrl,
  }) async {
    String imageUrl;

    final ref = _firebaseStorage.ref().child('user_profiles/$uid.jpg');
    await ref.putFile(profileImageUrl!);
    imageUrl = await ref.getDownloadURL();

    await _firestore.collection('users').doc(uid).update({
      'name': name,
      'profileImageUrl': imageUrl,
    });
    _updateCurrentUser(name, imageUrl);
  }

  void _updateCurrentUser(String name, String imageUrl) {
    AppUser? currentUser = SessionManager().currentUser;
    currentUser = currentUser?.copyWith(name: name, profileImageUrl: imageUrl);
    SessionManager().setUser(currentUser!);
  }

  Future<void> signout() async {
    await _auth.signOut();
  }

  bool get hasMore => _lastVisible != null;
}
