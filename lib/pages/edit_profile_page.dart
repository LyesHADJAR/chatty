import 'package:flutter/material.dart';
import 'package:chatty/components/button.dart';
import 'package:chatty/components/profile_image.dart';
import 'package:chatty/models/chat_user.dart';
import 'package:chatty/services/auth/auth_service.dart';
import 'package:chatty/services/storage/storage_service.dart';

class EditProfilePage extends StatefulWidget {
  final ChattyUser user;

  const EditProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _usernameController = TextEditingController();
  final _authService = AuthService();
  final _storageService = StorageService();
  bool _isLoading = false;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.user.username;
  }

  Future<void> _checkUsername(String username) async {
    if (username == widget.user.username) {
      setState(() => _usernameError = null);
      return;
    }

    if (username.length < 3) {
      setState(() => _usernameError = 'Username must be at least 3 characters');
      return;
    }
    
    // Check for valid characters (alphanumeric and underscore only)
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      setState(() => _usernameError = 'Only letters, numbers, and underscores allowed');
      return;
    }
    
    try {
      bool isAvailable = await _authService.isUsernameAvailable(username);
      setState(() => _usernameError = isAvailable ? null : 'Username already taken');
    } catch (e) {
      setState(() => _usernameError = 'Error checking username');
    }
  }

  Future<void> _saveChanges() async {
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username cannot be empty')),
      );
      return;
    }

    if (_usernameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_usernameError!)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Only update if username changed
      if (_usernameController.text.trim() != widget.user.username) {
        await _authService.updateUsername(_usernameController.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile image
            GestureDetector(
              onTap: () => _showProfileImageOptions(context),
              child: Stack(
                children: [
                  ProfileImage(
                    imageUrl: widget.user.profileImageUrl,
                    fallbackText: widget.user.username,
                    size: 120,
                    backgroundColor: theme.colorScheme.primary,
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
            
            const SizedBox(height: 32),
            
            // Email (read-only)
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Email',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email_outlined),
                hintText: widget.user.email,
              ),
              controller: TextEditingController(text: widget.user.email),
            ),
            
            const SizedBox(height: 16),
            
            // Username
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
                errorText: _usernameError,
              ),
              onChanged: _checkUsername,
            ),
            
            const SizedBox(height: 32),
            
            // Save button
            CustomButton(
              text: 'Save Changes',
              onTap: _saveChanges,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileImageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('Change avatar color'),
              onTap: () async {
                Navigator.pop(dialogContext);
                setState(() => _isLoading = true);
                
                try {
                  await _storageService.uploadProfileImage(null);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Avatar updated')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update avatar: $e')),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reset to default avatar'),
              onTap: () async {
                Navigator.pop(dialogContext);
                setState(() => _isLoading = true);
                
                try {
                  await _storageService.deleteProfileImage();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Avatar reset to default')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to reset avatar: $e')),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
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