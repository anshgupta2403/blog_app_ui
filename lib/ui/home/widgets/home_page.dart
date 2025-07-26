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
      LoadBlogs(category: categories[0], isRefresh: true),
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging ||
          _tabController.index == categories.length) {
        return;
      }

      final currentCategory = categories[_tabController.index];
      context.read<HomeBloc>().add(
        LoadBlogs(category: currentCategory, isRefresh: true),
      );
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
        LoadBlogs(category: currentCategory, isRefresh: true),
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
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white),
              onPressed: () {},
            ),
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
}

class BlogList extends StatefulWidget {
  final String category;
  const BlogList({super.key, required this.category});

  @override
  State<BlogList> createState() => _BlogListState();
}

class _BlogListState extends State<BlogList> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    // Removed initial load here to avoid duplicate fetch
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMoreBlogs();
    }
  }

  void _loadMoreBlogs() {
    if (mounted) {
      context.read<HomeBloc>().add(
        LoadBlogs(category: widget.category, isRefresh: false),
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
        if (state is BlogsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is BlogsLoaded && state.categoryBlogs.isNotEmpty) {
          final blogs = state.categoryBlogs;
          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: blogs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
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
                              isRefresh: true,
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
                            const CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              blog.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            PopupMenuButton<String>(
                              onSelected: (value) {},
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
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
            },
          );
        } else if (state is BlogsError) {
          return Center(child: Text('Error: ${state.message}'));
        } else {
          return const Center(child: Text('No blogs found.'));
        }
      },
    );
  }
}
