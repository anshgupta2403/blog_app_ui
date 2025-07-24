import 'package:blog_app/routing/routes.dart';
import 'package:blog_app/ui/home/bloc/home_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CreatePostBlogScreen extends StatefulWidget {
  const CreatePostBlogScreen({super.key});

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
        }
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(title: const Text('Create Blog Post')),
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
                          (selectedCategory == null ||
                              state is PublishPostRequested)
                          ? null
                          : () {
                              context.read<HomeBloc>().add(
                                PublishPost(
                                  title: titleController.text.trim(),
                                  content: contentController.text.trim(),
                                  category: selectedCategory!,
                                ),
                              );
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
                      child: state is PublishPostRequested
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Publish'),
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
