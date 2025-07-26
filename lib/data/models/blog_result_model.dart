import 'package:blog_app/data/models/blog_post_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BlogQueryResult {
  final List<BlogPost> blogs;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  BlogQueryResult({
    required this.blogs,
    required this.lastDoc,
    required this.hasMore,
  });
}
