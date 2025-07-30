import 'package:blog_app/routing/routes.dart';
import 'package:blog_app/ui/home/bloc/home_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CreatePostBlogScreen extends StatefulWidget {
  final String? title;
  final String? category;
  final String? postId;

  const CreatePostBlogScreen({
    super.key,
    this.title,
    this.category,
    this.postId,
  });

  @override
  State<CreatePostBlogScreen> createState() => _CreatePostBlogScreenState();
}

class _CreatePostBlogScreenState extends State<CreatePostBlogScreen> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  final List<String> categories = [
    'Tech',
    'Health',
    'Travel',
    'Education',
    'Food',
  ];
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.title != null) {
      titleController.text = widget.title!;
    }
    if (widget.category != null && widget.category?.trim() != '') {
      selectedCategory = widget.category;
    }
    if (widget.postId != null && widget.postId?.trim() != '') {
      context.read<HomeBloc>().add(LoadBlogDetails(widget.postId!));
    }
    print('PostId: ${widget.postId}');
    titleController.addListener(_onFormChange);
    contentController.addListener(_onFormChange);
  }

  void _onFormChange() {
    setState(() {}); // Rebuild when text changes
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is PublishPostSucess) {
          GoRouter.of(context).pushNamed(Routes.home);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post published successfully!')),
          );
        } else if (state is PublishPostFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is BlogDetailLoadingSuccess) {
          contentController.text = state.postContent;
        } else if (state is BlogDetailLoadingFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is UpdatePostSuccess) {
          GoRouter.of(context).pushNamed(Routes.home);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post updated successfully!')),
          );
        } else if (state is UpdatePostFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.postId?.trim() != ''
                  ? 'Edit Blog Post'
                  : 'Create Blog Post',
              style: TextStyle(color: Colors.white),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                GoRouter.of(context).pop();
              },
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Category'),
                  value: selectedCategory,
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedCategory = val),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TextField(
                    controller: contentController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                BlocBuilder<HomeBloc, HomeState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed:
                          (titleController.text.isEmpty ||
                              selectedCategory == null ||
                              contentController.text.isEmpty ||
                              state is PublishPostRequested ||
                              state is UpdatePostRequested)
                          ? null
                          : () {
                              final title = titleController.text.trim();
                              final content = contentController.text.trim();
                              final category = selectedCategory ?? 'Tech';

                              if (widget.postId?.trim().isNotEmpty ?? false) {
                                // Update existing post
                                context.read<HomeBloc>().add(
                                  UpdatePost(
                                    postId: widget.postId!.trim(),
                                    title: title,
                                    content: content,
                                    category: category,
                                  ),
                                );
                              } else {
                                // Create new post
                                context.read<HomeBloc>().add(
                                  PublishPost(
                                    title: title,
                                    content: content,
                                    category: category,
                                  ),
                                );
                              }
                            },
                      style: Theme.of(context).elevatedButtonTheme.style
                          ?.copyWith(
                            backgroundColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (titleController.text.isEmpty ||
                                  selectedCategory == null ||
                                  contentController.text.isEmpty) {
                                return Colors.deepPurpleAccent.shade100;
                              }
                              return Colors.deepPurpleAccent;
                            }),
                          ),
                      child:
                          state is PublishPostRequested ||
                              state is UpdatePostRequested
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              widget.postId?.trim() != ''
                                  ? 'Update'
                                  : 'Publish',
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
