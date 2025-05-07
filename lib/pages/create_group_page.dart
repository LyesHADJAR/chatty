import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chatty/components/button.dart';
import 'package:chatty/components/text_field.dart';
import 'package:chatty/components/profile_image.dart';
import 'package:chatty/components/user_tile.dart';
import 'package:chatty/services/chat/group_service.dart';
import 'package:chatty/services/storage/storage_service.dart';
import 'package:chatty/models/chat_user.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({Key? key}) : super(key: key);

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final GroupService _groupService = GroupService();
  final StorageService _storageService = StorageService();
  
  List<ChattyUser> _availableUsers = [];
  List<ChattyUser> _selectedUsers = [];
  List<ChattyUser> _filteredUsers = [];
  File? _groupImageFile;
  String? _imageUrl;
  bool _isLoading = false;
  bool _isCreating = false;
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  void _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      // Simulate loading users
      // In a real app, you'd fetch users from your service
      final snapshot = await FirebaseFirestore.instance.collection('Users').get();
      _availableUsers = snapshot.docs
          .map((doc) => ChattyUser.fromMap(doc.data()))
          .where((user) => user.uid != FirebaseAuth.instance.currentUser?.uid)
          .toList();
      
      _filteredUsers = List.from(_availableUsers);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_availableUsers);
      } else {
        _filteredUsers = _availableUsers
            .where((user) => 
                user.username.toLowerCase().contains(query.toLowerCase()) ||
                user.email.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }
  
  void _toggleUserSelection(ChattyUser user) {
    setState(() {
      if (_selectedUsers.any((u) => u.uid == user.uid)) {
        _selectedUsers.removeWhere((u) => u.uid == user.uid);
      } else {
        _selectedUsers.add(user);
      }
    });
  }
  
  void _pickGroupImage() async {
    try {
      final imageFile = await _storageService.pickImage(ImageSource.gallery);
      if (imageFile != null) {
        final croppedFile = await _storageService.cropImage(imageFile, context);
        if (croppedFile != null) {
          setState(() => _groupImageFile = croppedFile);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }
  
  void _createGroup() async {
    // Validate inputs
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }
    
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }
    
    setState(() => _isCreating = true);
    
    try {
      // Upload group image if selected
      if (_groupImageFile != null) {
        // Create a specific method for uploading group images in your StorageService
        _imageUrl = await _storageService.uploadGroupImage(_groupImageFile!);
      }
      
      // Get member IDs
      final memberIds = _selectedUsers.map((user) => user.uid).toList();
      
      // Create the group
      await _groupService.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrl,
        memberIds: memberIds,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group image and details
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickGroupImage,
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    image: _groupImageFile != null
                                        ? DecorationImage(
                                            image: FileImage(_groupImageFile!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: _groupImageFile == null
                                      ? Icon(
                                          Icons.people,
                                          size: 40,
                                          color: theme.colorScheme.primary,
                                        )
                                      : null,
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
                                      size: 16,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Group name field
                          CustomTextField(
                            hintText: 'Group Name',
                            controller: _nameController,
                            prefixIcon: Icons.group,
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Group description field
                          CustomTextField(
                            hintText: 'Group Description (Optional)',
                            controller: _descriptionController,
                            prefixIcon: Icons.description,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Selected users section
                    Text(
                      'Selected Members (${_selectedUsers.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    if (_selectedUsers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'No members selected',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedUsers.length,
                          itemBuilder: (context, index) {
                            final user = _selectedUsers[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 16, top: 8),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      ProfileImage(
                                        imageUrl: user.profileImageUrl,
                                        fallbackText: user.username,
                                        size: 50,
                                      ),
                                      Positioned(
                                        top: -4,
                                        right: -4,
                                        child: GestureDetector(
                                          onTap: () => _toggleUserSelection(user),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.error,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: theme.colorScheme.surface,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.close,
                                              size: 12,
                                              color: theme.colorScheme.onError,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      user.username,
                                      style: theme.textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Search for users
                    Text(
                      'Add Members',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    CustomTextField(
                      hintText: 'Search users...',
                      controller: _searchController,
                      prefixIcon: Icons.search,
                      onChanged: _filterUsers,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final isSelected = _selectedUsers.any((u) => u.uid == user.uid);
                        
                        return UserTile(
                          text: user.username,
                          subtitle: user.email,
                          profileImageUrl: user.profileImageUrl,
                          onTap: () => _toggleUserSelection(user),
                          isNewContact: !isSelected,
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleUserSelection(user),
                            activeColor: theme.colorScheme.primary,
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Create button
                    CustomButton(
                      text: 'Create Group',
                      onTap: _isCreating ? null : _createGroup,
                      isLoading: _isCreating,
                      prefixIcon: Icon(
                        Icons.check_circle_outline,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}