import 'dart:io';
import 'package:blog_app/routing/routes.dart';
import 'package:blog_app/ui/core/utils/session_manager_utils.dart';
import 'package:blog_app/ui/home/bloc/home_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final String? name;
  const EditProfileScreen({super.key, required this.name});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    if (widget.name != null) {
      _nameController.text = widget.name ?? '';
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileImageUrl = SessionManager().currentUser?.profileImageUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            GoRouter.of(context).pop();
          },
        ),
      ),
      body: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state is UpdateProfileSuccess) {
            context.pushNamed(Routes.profileScreen);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!')),
            );
          } else if (state is UpdateProfileFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!) as ImageProvider
                            : (profileImageUrl != null
                                  ? NetworkImage(profileImageUrl)
                                  : null),
                        child: _imageFile == null && profileImageUrl == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.deepPurpleAccent,
                          radius: 16,
                          child: Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed:
                      state is UpdateProfileRequested &&
                          _nameController.text.trim() == widget.name &&
                          _imageFile == null
                      ? null
                      : () {
                          context.read<HomeBloc>().add(
                            UpdateProfile(
                              _nameController.text,
                              SessionManager().currentUser?.uid,
                              _imageFile,
                            ),
                          );
                        },
                  style: ButtonStyle(
                    backgroundColor:
                        _nameController.text.trim() == widget.name &&
                            _imageFile == null
                        ? WidgetStateColor.resolveWith(
                            (_) => Colors.deepPurpleAccent.shade100,
                          )
                        : WidgetStateColor.resolveWith(
                            (_) => Colors.deepPurpleAccent,
                          ),
                  ),
                  child: state is UpdateProfileRequested
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Changes'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
