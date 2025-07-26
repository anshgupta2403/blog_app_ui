import 'package:blog_app/routing/router.dart';
import 'package:blog_app/routing/routes.dart';
import 'package:blog_app/ui/core/utils/common_utils.dart';
import 'package:blog_app/ui/home/bloc/home_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:blog_app/ui/core/utils/session_manager_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionManager().currentUser;

    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is SignOutSuccess) {
          context.pushNamed(Routes.login);
        } else if (state is SignOutFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                title: const Text(
                  'My Profile',
                  style: TextStyle(color: Colors.white),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () {
                      context.read<HomeBloc>().add(SignOut());
                    },
                  ),
                ],
              ),
              body: Column(
                children: [
                  const SizedBox(height: 24),
                  CircleAvatar(
                    radius: 45,
                    backgroundImage: user?.profileImageUrl != null
                        ? NetworkImage(user?.profileImageUrl ?? '')
                        : null,
                    child: user?.profileImageUrl == null
                        ? const Icon(Icons.person, size: 45)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'No Name',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat('Posts', user?.totalPosts),
                        _buildStat('Likes', user?.totalLikes),
                        _buildStat('Followers', user?.followersCount),
                        _buildStat('Following', user?.followingCount),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.pushNamed(
                        Routes.editProfile,
                        pathParameters: {'name': user?.name ?? 'No Name'},
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Your Posts',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.filter_alt_outlined),
                                onPressed: () async {
                                  final result =
                                      await showModalBottomSheet<
                                        Map<String, dynamic>
                                      >(
                                        context: context,
                                        builder: (_) => const FilterSortModal(),
                                      );
                                  if (result != null) {
                                    final uid =
                                        SessionManager().currentUser?.uid;
                                    context.read<HomeBloc>().add(
                                      ApplyFilters(
                                        uid: uid,
                                        sortBy: result['sortBy'],
                                        categories: result['categories'],
                                        startDate: result['startDate'],
                                        endDate: result['endDate'],
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const Expanded(child: BlogList()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (state is SignOutRequested)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Signing out...',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStat(String label, int? count) {
    return Column(
      children: [
        Text(
          '${count ?? 0}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(label),
      ],
    );
  }
}

class FilterSortModal extends StatefulWidget {
  const FilterSortModal({super.key});

  @override
  State<FilterSortModal> createState() => _FilterSortModalState();
}

class _FilterSortModalState extends State<FilterSortModal> {
  final List<String> categories = ['Tech', 'Travel', 'Lifestyle', 'Education'];
  final List<String> sortOptions = ['Recent', 'Popular'];

  final Set<String> selectedCategories = {};
  String? selectedSort;
  DateTimeRange? selectedDateRange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Wrap(
          runSpacing: 16,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Filter & Sort',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            // Category Chips
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Category',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: categories.map((cat) {
                    final isSelected = selectedCategories.contains(cat);
                    return FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            selectedCategories.add(cat);
                          } else {
                            selectedCategories.remove(cat);
                          }
                        });
                      },
                      selectedColor: Colors.deepPurpleAccent,
                      showCheckmark: true,
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // Sort Options Toggle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sort By',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ToggleButtons(
                  isSelected: sortOptions
                      .map((s) => s == selectedSort)
                      .toList(growable: false),
                  onPressed: (index) {
                    setState(() {
                      selectedSort = sortOptions[index];
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  selectedColor: Colors.white,
                  fillColor: Colors.deepPurpleAccent,
                  color: Colors.black87,
                  constraints: const BoxConstraints(
                    minWidth: 100,
                    minHeight: 40,
                  ),
                  children: sortOptions
                      .map(
                        (sort) =>
                            Text(sort, style: const TextStyle(fontSize: 14)),
                      )
                      .toList(),
                ),
              ],
            ),

            // Date Range Picker
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Date Range',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      initialDateRange: selectedDateRange,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDateRange = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDateRange != null
                              ? "${DateFormat('dd MMM yyyy').format(selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(selectedDateRange!.end)}"
                              : 'Select date range',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Apply Button
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, {
                      'categories': selectedCategories.toList(),
                      'sortBy': selectedSort,
                      'startDate': selectedDateRange?.start,
                      'endDate': selectedDateRange?.end,
                    });
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Apply Filters'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BlogList extends StatefulWidget {
  const BlogList({super.key});

  @override
  State<BlogList> createState() => _BlogListState();
}

class _BlogListState extends State<BlogList> with RouteAware {
  late ScrollController _scrollController;
  final currentUserId = SessionManager().currentUser?.uid;

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(FetchInitialUserBlogs(currentUserId));
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final bloc = context.read<HomeBloc>();
    final state = bloc.state;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (state is ProfileBlogLoaded && state.hasMore) {
        bloc.add(FetchMoreUserBlogs(currentUserId));
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  // Called when coming back to this page
  @override
  void didPopNext() {
    context.read<HomeBloc>().add(FetchInitialUserBlogs(currentUserId));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is ProfileBlogError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Failed to load blogs')));
        } else if (state is DeleteBlogSucess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Blog deleted successfully!')),
          );
          context.read<HomeBloc>().add(FetchInitialUserBlogs(currentUserId));
        } else if (state is DeleteBlogError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        if (state is ProfileBlogLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ProfileBlogLoaded && state.blogs.isNotEmpty) {
          final blogs = state.blogs;
          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: blogs.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index < blogs.length) {
                final blog = blogs[index];
                return InkWell(
                  onTap: () {
                    context
                        .pushNamed(
                          Routes.blogDetails,
                          extra: {'postId': blog.postId, 'summary': blog},
                        )
                        .then((_) {
                          if (mounted) {
                            context.read<HomeBloc>().add(
                              FetchInitialUserBlogs(currentUserId),
                            );
                          }
                        });
                  },
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            blog.preview.length >= 100
                                ? '${blog.preview.substring(0, 100)}...'
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
                              const Spacer(),
                              PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    context.pushNamed(
                                      Routes.blogPost,
                                      pathParameters: {
                                        'title': blog.title,
                                        'category': blog.category,
                                        'postId': blog.postId,
                                      },
                                    );
                                  } else if (value == 'delete') {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Post'),
                                        content: const Text(
                                          'Are you sure you want to delete this post?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      context.read<HomeBloc>().add(
                                        DeleteBlog(blog.postId),
                                      );
                                    }
                                  }
                                },
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
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
            },
          );
        } else if (state is ProfileBlogError) {
          return Center(child: Text('Error: ${state.message}'));
        } else {
          return const Center(child: Text('No blogs found.'));
        }
      },
    );
  }
}
