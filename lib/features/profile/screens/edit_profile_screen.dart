import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();
  late TextEditingController _displayNameController;
  File? _selectedImage;
  String? _newPhotoUrl;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _displayNameController = TextEditingController(
      text: authProvider.appUser?.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();

      // Show dialog to choose camera or gallery
      final result = await showDialog<String>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Select Photo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Camera'),
                    onTap: () => Navigator.of(context).pop('camera'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Gallery'),
                    onTap: () => Navigator.of(context).pop('gallery'),
                  ),
                ],
              ),
            ),
      );

      if (result != null) {
        final XFile? image = await picker.pickImage(
          source: result == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 80,
        );

        if (image != null) {
          setState(() {
            _selectedImage = File(image.path);
          });

          // Upload image to Firebase Storage
          await _uploadProfileImage();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_selectedImage == null) return;

    try {
      // Show loading indicator
      setState(() {
        _isUpdating = true;
      });

      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.appUser?.id;
      if (userId == null) return;

      final fileName = '${_uuid.v4()}.jpg';
      final path = 'profile_pictures/$userId/$fileName';

      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(_selectedImage!);
      final url = await uploadTask.ref.getDownloadURL();

      setState(() {
        _newPhotoUrl = url;
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture uploaded successfully!'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.updateUserProfile(
        displayName: _displayNameController.text.trim(),
        photoUrl: _newPhotoUrl,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${authProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor:
            isDark ? const Color(0xFF2D2D30) : AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        actions: [
          TextButton(
            onPressed: _isUpdating ? null : _updateProfile,
            child:
                _isUpdating
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          children: [
            // Profile photo section
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primaryGreen.withOpacity(
                          0.2,
                        ),
                        child:
                            _selectedImage != null
                                ? ClipOval(
                                  child: Image.file(
                                    _selectedImage!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : (authProvider.appUser?.photoUrl != null &&
                                    authProvider
                                        .appUser!
                                        .photoUrl!
                                        .isNotEmpty &&
                                    !authProvider.appUser!.photoUrl!.contains(
                                      'example.com',
                                    ))
                                ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: authProvider.appUser!.photoUrl!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    placeholder:
                                        (context, url) =>
                                            const CircularProgressIndicator(),
                                    errorWidget:
                                        (context, url, error) => const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: AppColors.primaryGreen,
                                        ),
                                  ),
                                )
                                : const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppColors.primaryGreen,
                                ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            onPressed: _pickImage,
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.marginS),
                  Text(
                    'Tap to change photo',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.marginL),

            // Display name field
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2D30) : Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : Colors.grey).withOpacity(
                      0.1,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Display Name',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.marginS),
                  TextFormField(
                    controller: _displayNameController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your display name',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusS,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusS,
                        ),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusS,
                        ),
                        borderSide: const BorderSide(
                          color: AppColors.primaryGreen,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a display name';
                      }
                      if (value.trim().length < 2) {
                        return 'Display name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.marginL),

            // Email field (read-only)
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2D30) : Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : Colors.grey).withOpacity(
                      0.1,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.marginS),
                  TextFormField(
                    initialValue: authProvider.appUser?.email ?? '',
                    enabled: false,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusS,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusS,
                        ),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : Colors.grey.shade200,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.marginXS),
                  Text(
                    'Email cannot be changed',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
