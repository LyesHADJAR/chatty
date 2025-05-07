import 'package:chatty/components/profile_image.dart';
import 'package:chatty/models/chat_user.dart';
import 'package:chatty/services/storage/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:chatty/services/auth/auth_service.dart';
import 'package:image_picker/image_picker.dart';

class SettingsPage extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;

  const SettingsPage({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _authService = AuthService();
  bool _isLoading = false; 

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: FutureBuilder<ChattyUser?>(
        future: _authService.getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;

          return ListView(
            children: [
              // Profile section - New section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _showProfileImageOptions(context),
                      child: Stack(
                        children: [
                          ProfileImage(
                            imageUrl: user?.profileImageUrl,
                            fallbackText: user?.username ?? user?.email ?? '',
                            size: 120,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.surface,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      user?.username ?? '',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      user?.email ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Rest of the settings page...
              // (Keep your existing settings sections here)
            ],
          );
        },
      ),
    );
  }

  // Add this method to handle profile image selection
  void _showProfileImageOptions(BuildContext context) {
    final storageService = StorageService();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take a photo'),
                  onTap: () async {
                    Navigator.pop(context);

                    final imageFile = await storageService.pickImage(
                      ImageSource.camera,
                    );
                    if (imageFile != null) {
                      final croppedFile = await storageService.cropImage(
                        imageFile,
                        context,
                      );
                      if (croppedFile != null) {
                        setState(() => _isLoading = true);
                        try {
                          await storageService.uploadProfileImage(croppedFile);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile picture updated'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to update profile picture: $e',
                                ),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
                        }
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery'),
                  onTap: () async {
                    Navigator.pop(context);

                    final imageFile = await storageService.pickImage(
                      ImageSource.gallery,
                    );
                    if (imageFile != null) {
                      final croppedFile = await storageService.cropImage(
                        imageFile,
                        context,
                      );
                      if (croppedFile != null) {
                        setState(() => _isLoading = true);
                        try {
                          await storageService.uploadProfileImage(croppedFile);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile picture updated'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to update profile picture: $e',
                                ),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
                        }
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Remove profile picture',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(context);

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Remove Profile Picture'),
                            content: const Text(
                              'Are you sure you want to remove your profile picture?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                    );

                    if (confirm == true) {
                      setState(() => _isLoading = true);
                      try {
                        await storageService.deleteProfileImage();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile picture removed'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to remove profile picture: $e',
                              ),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isLoading = false);
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }
}
