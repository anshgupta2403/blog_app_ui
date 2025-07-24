import 'package:blog_app/routing/routes.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);

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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshCurrentTab();
    }
  }

  void _refreshCurrentTab() {
    final currentIndex = _tabController.index;
    if (currentIndex < categories.length) {
      final currentCategory = categories[currentIndex];
      context.read<HomeBloc>().add(
        LoadBlogs(category: currentCategory, isRefresh: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      appBar: AppBar(
        toolbarHeight: 72,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.deepPurpleAccent),
              ),
              onPressed: () {
                // Navigate to profile screen if needed
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: const [
                    Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white),
              onPressed: () {
                // Handle notification icon press
              },
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
          GoRouter.of(context).pushNamed(Routes.blogPost);
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
    _loadBlogs(isRefresh: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadBlogs();
    }
  }

  Future<void> _loadBlogs({bool isRefresh = false}) async {
    context.read<HomeBloc>().add(
      LoadBlogs(category: widget.category, isRefresh: isRefresh),
    );
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
          final blogs = state.categoryBlogs[widget.category] ?? [];
          return RefreshIndicator(
            onRefresh: () => _loadBlogs(isRefresh: true),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: blogs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final blog = blogs[index];
                return InkWell(
                  onTap: () {
                    GoRouter.of(context).pushNamed(
                      Routes.blogDetails,
                      extra: {'postId': blog.postId, 'summary': blog},
                    );
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
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
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
