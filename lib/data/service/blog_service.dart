import 'dart:io';

import 'package:blog_app/data/models/app_notification_model.dart';
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
    final user = _auth.currentUser;
    if (user == null) return;

    final authorDoc = await _firestore.collection('users').doc(user.uid).get();
    final authorName = authorDoc['name'] ?? 'Anonymous';

    final postRef = _firestore.collection('posts_summary').doc();
    final usersRef = _firestore.collection('users').doc(user.uid);

    await _firestore.runTransaction((txn) async {
      final userSnapshot = await txn.get(usersRef);
      final totalPosts = userSnapshot.data()?['totalPosts'] ?? 0;

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
        'authorImage': authorDoc['profileImageUrl'],
      });

      txn.set(_firestore.collection('posts_content').doc(postRef.id), {
        'postId': postRef.id,
        'content': content,
      });

      txn.update(usersRef, {'totalPosts': totalPosts + 1});
    });
  }

  Future<List<DocumentSnapshot>> getBlogsByCategory({
    required String category,
    required int limit,
    required bool isRefresh,
    required DocumentSnapshot? lastDoc,
  }) async {
    Query query = _firestore
        .collection('posts_summary')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }
    if (SessionManager().currentUser == null) {
      await getCurrentUser(_auth.currentUser?.uid);
    }

    final snapshot = await query.get();

    return snapshot.docs;
  }

  Future<void> getCurrentUser(String? uid) async {
    final user = await _firestore.collection('users').doc(uid).get();
    SessionManager().setUser(user.data()!);
  }

  void resetPagination() {
    _lastVisible = null;
  }

  Future<DocumentSnapshot> getBlogById(String postId) async {
    return await _firestore.collection('posts_content').doc(postId).get();
  }

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
    final commentRef = postRef.collection('comments').doc();

    final commentData = {
      'commentId': commentRef.id,
      'userId': comment.uid,
      'userName': comment.authorName,
      'commentText': comment.message,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.runTransaction((txn) async {
      final postSnapshot = await txn.get(postRef);
      if (!postSnapshot.exists) {
        throw Exception('Post does not exist');
      }

      txn.set(commentRef, commentData);
      txn.update(postRef, {'numComments': FieldValue.increment(1)});
    });
  }

  Future<void> toggleLikePost(
    String postId,
    String userId,
    String authorId,
  ) async {
    final postRef = _firestore.collection('posts_summary').doc(postId);
    final likeRef = postRef.collection('likes').doc(userId);
    final userRef = _firestore.collection('users').doc(authorId);

    await _firestore.runTransaction((txn) async {
      final likeSnapshot = await txn.get(likeRef);
      final postSnapshot = await txn.get(postRef);
      final userSnapshot = await txn.get(userRef);

      int currentLikes = postSnapshot.data()?['numLikes'] ?? 0;
      int totalLikes = userSnapshot.data()?['totalLikes'] ?? 0;

      if (likeSnapshot.exists) {
        txn.delete(likeRef);
        txn.update(postRef, {'numLikes': currentLikes - 1});
        txn.update(userRef, {'totalLikes': totalLikes - 1});
      } else {
        txn.set(likeRef, {'likedAt': FieldValue.serverTimestamp()});
        txn.update(postRef, {'numLikes': currentLikes + 1});
        txn.update(userRef, {'totalLikes': totalLikes + 1});
      }
    });
  }

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
    final usersRef = _firestore.collection('users').doc(authorId);
    final authorRef = _firestore.collection('users').doc(followerId);

    final followerRef = usersRef.collection('followers').doc(followerId);
    final followingRef = authorRef.collection('following').doc(authorId);

    await _firestore.runTransaction((txn) async {
      final userSnapshot = await txn.get(usersRef);
      final authorSnapshot = await txn.get(authorRef);

      int followersCount = userSnapshot.data()?['followersCount'] ?? 0;
      int followingCount = authorSnapshot.data()?['followingCount'] ?? 0;

      txn.set(followerRef, {
        'followerId': followerId,
        'followedAt': FieldValue.serverTimestamp(),
      });
      txn.set(followingRef, {
        'authorId': authorId,
        'followedAt': FieldValue.serverTimestamp(),
      });
      txn.update(usersRef, {'followersCount': followersCount + 1});
      txn.update(authorRef, {'followingCount': followingCount + 1});
    });
  }

  Future<void> unfollowAuthor(String followerId, String authorId) async {
    final usersRef = _firestore.collection('users').doc(authorId);
    final authorRef = _firestore.collection('users').doc(followerId);

    final followingRef = authorRef.collection('following').doc(authorId);
    final followersRef = usersRef.collection('followers').doc(followerId);

    await _firestore.runTransaction((txn) async {
      final userSnapshot = await txn.get(usersRef);
      final authorSnapshot = await txn.get(authorRef);

      int followersCount = userSnapshot.data()?['followersCount'] ?? 0;
      int followingCount = authorSnapshot.data()?['followingCount'] ?? 0;

      txn.delete(followingRef);
      txn.delete(followersRef);
      txn.update(usersRef, {'followersCount': followersCount - 1});
      txn.update(authorRef, {'followingCount': followingCount - 1});
    });
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

  Future<List<DocumentSnapshot>> searchBlogsByTitle({
    required String searchQuery,
    required String category,
    required int limit,
    DocumentSnapshot? lastDoc,
  }) async {
    var query = _firestore
        .collection('posts_summary')
        .where('category', isEqualTo: category)
        .where(
          'titleLowercase',
          isGreaterThanOrEqualTo: searchQuery.toLowerCase(),
        )
        .where('titleLowercase', isLessThan: '${searchQuery.toLowerCase()}')
        .orderBy('titleLowercase')
        .limit(limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snaphots = await query.get();
    return snaphots.docs;
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
    required String? name,
    required String? uid,
    required File? profileImageFile,
  }) async {
    if (uid == null) return;

    final userRef = _firestore.collection('users').doc(uid);
    String? imageUrl;

    // Step 1: Upload new profile image and update Firestore
    if (profileImageFile != null) {
      final ref = _firebaseStorage.ref().child('user_profiles/$uid.jpg');
      await ref.putFile(profileImageFile);
      imageUrl = await ref.getDownloadURL();

      // Update user's profile image
      await userRef.update({'profileImageUrl': imageUrl});
      _updateProfileImage(imageUrl);
    }

    // Step 2: Update name if provided
    if (name != null) {
      await userRef.update({'name': name});
      _updateName(name);
    }

    // Step 3: Update all user's post summaries with new name and/or image
    if (name != null || imageUrl != null) {
      final userPosts = await _firestore
          .collection('posts_summary')
          .where('uid', isEqualTo: uid)
          .get();

      final batch = _firestore.batch();
      for (final doc in userPosts.docs) {
        final updates = <String, dynamic>{};
        if (name != null) updates['authorName'] = name;
        if (imageUrl != null) updates['authorImage'] = imageUrl;
        batch.update(doc.reference, updates);
      }

      await batch.commit();
    }
  }

  void _updateName(String name) {
    final currentUser = SessionManager().currentUser;
    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(name: name).toMap();
    SessionManager().setUser(updatedUser);
  }

  void _updateProfileImage(String imageUrl) {
    final currentUser = SessionManager().currentUser;
    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(profileImageUrl: imageUrl).toMap();
    SessionManager().setUser(updatedUser);
  }

  Future<void> signout() async {
    await _auth.signOut();
  }

  Stream<List<AppNotification>> fetchNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotification.fromSnapshot(doc))
              .toList(),
        );
  }

  Future<void> markAsRead(String notificationId, String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> deleteNotification(String notificationId, String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  Future<BlogPost> getBlogSummary(String postId) async {
    final result = await _firestore
        .collection('posts_summary')
        .doc(postId)
        .get();
    return BlogPost.fromSnapshot(result);
  }

  bool get hasMore => _lastVisible != null;
}
