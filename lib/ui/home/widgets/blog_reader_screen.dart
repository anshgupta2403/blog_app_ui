import 'package:blog_app/data/models/blog_post_model.dart';
import 'package:blog_app/data/models/comment_model.dart';
import 'package:blog_app/ui/core/utils/common_utils.dart';
import 'package:blog_app/ui/core/utils/session_manager_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../home/bloc/home_bloc.dart';

class BlogReaderScreen extends StatefulWidget {
  final String postId;
  final BlogPost? summary;

  const BlogReaderScreen({super.key, required this.postId, this.summary});

  @override
  State<BlogReaderScreen> createState() => _BlogReaderScreenState();
}

class _BlogReaderScreenState extends State<BlogReaderScreen> {
  BlogPost? summary;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<HomeBloc>();
    bloc.add(LoadBlogDetails(widget.postId));
    bloc.add(LoadComments(widget.postId));
    if (widget.summary == null) {
      bloc.add(LoadBlogSummary(widget.postId));
    } else {
      setState(() {
        summary = widget.summary;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is LoadBlogSummarySuccess) {
          setState(() {
            summary = state.summary;
          });
          final authorId = summary!.uid;
          final currentUserId = SessionManager().currentUser?.uid;
          if (currentUserId != null) {
            context.read<HomeBloc>().add(
              CheckFollowStatus(currentUserId, authorId),
            );
          }
        }
      },
      builder: (context, state) {
        if (summary == null) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              summary?.category ?? '',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  final deepLink =
                      'https://blog-app-f2ee1.web.app/blog-details?id=${widget.postId}';

                  final shareText =
                      '''📝 *${summary!.title}* \n👤 by *${summary!.authorName}*\n\n"${summary!.preview}"\n\n👉 Read the full blog here:\n$deepLink''';
                  SharePlus.instance.share(ShareParams(text: shareText));
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  children: [
                    Text(
                      summary!.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CommonUtil.formatRelativeDate(summary!.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        const CircleAvatar(child: Icon(Icons.person)),
                        const SizedBox(width: 10),
                        Text(
                          summary!.authorName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 10),
                        BlocConsumer<HomeBloc, HomeState>(
                          listenWhen: (previous, current) =>
                              current is FollowStatusFailure,
                          listener: (context, state) {
                            if (state is FollowStatusFailure) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(state.message)),
                              );
                            }
                          },
                          builder: (context, state) {
                            final isFollowing =
                                state is FollowStatusSuccess &&
                                state.isFollowing;
                            return OutlinedButton(
                              onPressed: () {
                                final currentUserId =
                                    SessionManager().currentUser?.uid;
                                final targetUserId = summary!.uid;

                                if (isFollowing) {
                                  context.read<HomeBloc>().add(
                                    UnfollowAuthor(currentUserId, targetUserId),
                                  );
                                } else {
                                  context.read<HomeBloc>().add(
                                    FollowAuthor(currentUserId, targetUserId),
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                side: const BorderSide(color: Colors.black),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                isFollowing ? 'Unfollow' : 'Follow',
                                style: const TextStyle(color: Colors.black),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    BlocBuilder<HomeBloc, HomeState>(
                      buildWhen: (prev, curr) =>
                          curr is BlogDetailLoading ||
                          curr is BlogDetailLoadingSuccess ||
                          curr is BlogDetailLoadingFailure,
                      builder: (context, state) {
                        if (state is BlogDetailLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (state is BlogDetailLoadingSuccess) {
                          return Text(
                            state.postContent,
                            style: const TextStyle(fontSize: 16, height: 1.6),
                          );
                        } else if (state is BlogDetailLoadingFailure) {
                          return Text(
                            'Error: ${state.message}',
                            style: const TextStyle(color: Colors.red),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Comments (${summary!.numComments})',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _StickyBottomBar(
                          postId: widget.postId,
                          summary: summary!,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<HomeBloc, HomeState>(
                      builder: (context, state) {
                        if (state is CommentsLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (state is CommentsError) {
                          return Text(
                            'Failed to load comments: ${state.message}',
                          );
                        } else if (state is CommentsLoaded ||
                            state is CommentAddedLocally) {
                          final comments = state is CommentsLoaded
                              ? state.comments
                              : [];
                          return AnimatedCommentList(initialComments: comments);
                        } else {
                          return const SizedBox();
                        }
                      },
                    ),
                  ],
                ),
              ),
              _CommentInputBar(postId: widget.postId),
            ],
          ),

          // Comment Input Bar

          // Bottom bar
        );
      },
    );
  }
}

class _CommentInputBar extends StatefulWidget {
  final String postId;

  const _CommentInputBar({required this.postId});

  @override
  State<_CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<_CommentInputBar> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<HomeBloc>();
    final state = bloc.state;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          state is AddCommentRequested
              ? const CircularProgressIndicator()
              : IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurple),
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      final user = SessionManager().currentUser;
                      print('BlogReaderScreen: ${user?.name} ${user?.uid}');
                      final comment = Comment(
                        controller.text.trim(),
                        DateTime.now(),
                        user?.uid,
                        user?.name,
                      );
                      bloc.add(AddComment(widget.postId, comment));
                      controller.clear();
                    }
                  },
                ),
        ],
      ),
    );
  }
}

class _StickyBottomBar extends StatefulWidget {
  final String postId;
  final BlogPost summary;

  const _StickyBottomBar({required this.postId, required this.summary});

  @override
  State<_StickyBottomBar> createState() => _StickyBottomBarState();
}

class _StickyBottomBarState extends State<_StickyBottomBar> {
  int _likeCount = 0;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _isLiked = false;
    _likeCount = widget.summary.numLikes;
    context.read<HomeBloc>().add(
      CheckIfPostLiked(widget.postId, SessionManager().currentUser?.uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        BlocConsumer<HomeBloc, HomeState>(
          listener: (context, state) {
            if (state is PostLikeUpdated) {
              final newLikeStatus = state.isLiked;
              if (_isLiked != newLikeStatus) {
                setState(() {
                  _isLiked = newLikeStatus;
                  _likeCount += newLikeStatus ? 1 : -1;
                });
              }
            }
          },
          builder: (context, state) {
            return IconButton(
              icon: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: Colors.deepPurple,
              ),
              onPressed: () {
                context.read<HomeBloc>().add(
                  ToggleLikePost(
                    widget.postId,
                    SessionManager().currentUser?.uid,
                    widget.summary.uid,
                  ),
                );
              },
            );
          },
        ),
        Text('$_likeCount'),
      ],
    );
  }
}

class AnimatedCommentList extends StatefulWidget {
  final List<dynamic> initialComments;

  const AnimatedCommentList({super.key, required this.initialComments});

  @override
  State<AnimatedCommentList> createState() => _AnimatedCommentListState();
}

class _AnimatedCommentListState extends State<AnimatedCommentList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  late List<Comment> _comments;

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.initialComments);
  }

  void _insertNewComment(Comment comment) {
    _comments.insert(0, comment);
    _listKey.currentState?.insertItem(
      0,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is CommentAddedLocally) {
          _insertNewComment(state.newComment);
        } else if (state is CommentsLoaded) {
          setState(() {
            _comments = List.from(state.comments);
          });
        }
      },
      child: SizedBox(
        height: 300,
        child: AnimatedList(
          key: _listKey,
          initialItemCount: _comments.length,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          itemBuilder: (context, index, animation) {
            final comment = _comments[index];
            return SizeTransition(
              sizeFactor: animation,
              child: _buildCommentTile(comment),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCommentTile(Comment comment) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(
          comment.authorName ?? 'Anonymous',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(comment.message),
        trailing: Text(
          _formatTime(comment.createAt),
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
