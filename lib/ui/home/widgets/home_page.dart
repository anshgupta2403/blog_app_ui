import 'dart:async';

import 'package:blog_app/data/models/blog_post_model.dart';
import 'package:blog_app/routing/router.dart';
import 'package:blog_app/routing/routes.dart';
import 'package:blog_app/ui/core/utils/common_utils.dart';
import 'package:blog_app/ui/core/utils/session_manager_utils.dart';
import 'package:blog_app/ui/home/bloc/home_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  final textFieldController = TextEditingController();

  final List<String> categories = [
    'Tech',
    'Health',
    'Travel',
    'Education',
    'Food',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length + 1, vsync: this);

    // Initial fetch for the first tab
    context.read<HomeBloc>().add(
      LoadBlogs(category: categories[0], categoryChange: true),
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging ||
          _tabController.index == categories.length) {
        return;
      }

      final currentCategory = categories[_tabController.index];
      context.read<HomeBloc>().add(
        LoadBlogs(category: currentCategory, categoryChange: true),
      );
      textFieldController.text = '';
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _tabController.dispose();
    super.dispose();
  }

  // Called when coming back to this page
  @override
  void didPopNext() {
    _refreshCurrentTab();
  }

  void _refreshCurrentTab() {
    final currentIndex = _tabController.index;
    if (currentIndex < categories.length && mounted) {
      final currentCategory = categories[currentIndex];
      context.read<HomeBloc>().add(
        LoadBlogs(category: currentCategory, categoryChange: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileImageUrl = SessionManager().currentUser?.profileImageUrl;
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      appBar: AppBar(
        toolbarHeight: 72,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            InkWell(
              onTap: () {
                context.pushNamed(Routes.profileScreen);
              },
              child: CircleAvatar(
                radius: 22,
                backgroundImage: profileImageUrl != null
                    ? NetworkImage(profileImageUrl)
                    : null,
                backgroundColor: Colors.white,
                child: profileImageUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 45,
                        color: Colors.deepPurpleAccent,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 25),
            Expanded(
              child: SizedBox(
                height: 44,
                child: TextField(
                  onChanged: (query) {
                    context.read<HomeBloc>().add(
                      SearchQueryChanged(
                        query.trim(),
                        categories[_tabController.index],
                      ),
                    );
                  },
                  controller: textFieldController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search blogs...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(color: Colors.deepPurple.shade100),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(
                        color: Colors.deepPurple.shade300,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            NotificationIcon(onTap: () => showNotificationsSheet(context)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            ...categories.map((c) => Tab(text: c)),
            const Tab(icon: Icon(Icons.add)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ...categories.map((category) => BlogList(category: category)),
          const Center(
            child: Text('Add Category', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        foregroundColor: Colors.white,
        onPressed: () {
          context
              .pushNamed(
                Routes.blogPost,
                pathParameters: {'title': ' ', 'category': ' ', 'postId': ' '},
              )
              .then((_) {
                _refreshCurrentTab(); // Refresh when coming back
              });
        },
        child: const Icon(Icons.edit),
      ),
    );
  }

  void showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: const NotificationList(),
      ),
    );
  }
}

class NotificationIcon extends StatelessWidget {
  final VoidCallback onTap;

  const NotificationIcon({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is NotificationError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        int unread = 0;
        if (state is NotificationLoaded) unread = state.unreadCount;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white),
              onPressed: onTap,
            ),
            if (unread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unread',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class NotificationList extends StatefulWidget {
  const NotificationList({super.key});

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(
      LoadNotifications(SessionManager().currentUser?.uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = SessionManager().currentUser;
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is NotificationLoading) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (state is NotificationLoaded) {
          final notifications = state.notifications;

          return ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Dismissible(
                key: Key(notification.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  context.read<HomeBloc>().add(
                    DeleteNotification(notification.id, currentUser?.uid),
                  );
                },
                child: ListTile(
                  title: Text(notification.title),
                  subtitle: Text(notification.body),
                  onTap: () {
                    context.read<HomeBloc>().add(
                      MarkNotificationAsRead(notification.id, currentUser?.uid),
                    );
                  },
                  tileColor: notification.isRead
                      ? Colors.grey[200]
                      : Colors.white,
                ),
              );
            },
          );
        } else {
          return const Center(child: Text('No notifications'));
        }
      },
    );
  }

  String timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class BlogList extends StatefulWidget {
  final String category;
  const BlogList({super.key, required this.category});

  @override
  State<BlogList> createState() => _BlogListState();
}

class _BlogListState extends State<BlogList> {
  late ScrollController _scrollController;
  Map<String, List<BlogPost>> blogs = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels != 0) {
        _loadMoreBlogs();
      }
    }
  }

  void _loadMoreBlogs() {
    if (mounted) {
      context.read<HomeBloc>().add(
        LoadBlogs(category: widget.category, categoryChange: false),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is BlogsLoading && state.isFirstFetch) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is BlogsLoaded && state.categoryBlogs.isEmpty) {
          return Center(child: Text('No blogs found'));
        }
        if (state is BlogsError) {
          return const Center(child: Text('No blogs found.'));
        }

        List<BlogPost> blogs = [];
        bool isLoading = false;

        if (state is BlogsLoading) {
          blogs = state.oldBlogs;
          isLoading = true;
        } else if (state is BlogsLoaded) {
          blogs = state.categoryBlogs;
        }

        return ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          itemCount: blogs.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index < blogs.length) {
              final blog = blogs[index];
              return InkWell(
                onTap: () {
                  context
                      .push(
                        Routes.blogDetails,
                        extra: {'postId': blog.postId, 'summary': blog},
                      )
                      .then((_) {
                        if (mounted) {
                          context.read<HomeBloc>().add(
                            LoadBlogs(
                              category: widget.category,
                              categoryChange: true,
                            ),
                          );
                        }
                      });
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: blog.authorImage != ''
                                  ? NetworkImage(blog.authorImage)
                                  : null,
                              child: blog.authorImage == ''
                                  ? Icon(Icons.person, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              blog.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          blog.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          blog.preview.length == 100
                              ? '${blog.preview}...'
                              : blog.preview,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.favorite_border,
                              size: 20,
                              color: Colors.deepPurple,
                            ),
                            const SizedBox(width: 4),
                            Text(blog.numLikes.toString()),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.comment_outlined,
                              size: 20,
                              color: Colors.deepPurple,
                            ),
                            const SizedBox(width: 4),
                            Text(blog.numComments.toString()),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.schedule,
                              size: 18,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              CommonUtil.formatRelativeDate(blog.createdAt),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              Timer(Duration(milliseconds: 30), () {
                _scrollController.jumpTo(
                  _scrollController.position.maxScrollExtent,
                );
              });
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: isLoading
                      ? CircularProgressIndicator()
                      : Text('No more blogs'),
                ),
              );
            }
          },
        );
      },
    );
  }
}
