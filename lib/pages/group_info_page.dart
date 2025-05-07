import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chatty/components/profile_image.dart';
import 'package:chatty/services/chat/group_service.dart';
import 'package:chatty/services/storage/storage_service.dart';
import 'package:chatty/models/group.dart';
import 'package:chatty/models/chat_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class GroupInfoPage extends StatefulWidget {
  final String groupId;

  const GroupInfoPage({super.key, required this.groupId});

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  final GroupService _groupService = GroupService();
  final StorageService _storageService = StorageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;

  void _toggleEdit() {
    setState(() => _isEditing = !_isEditing);
  }

  void _saveChanges(Group group) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name cannot be empty')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _groupService.updateGroupInfo(
        groupId: widget.groupId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Group info updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update group: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _changeGroupImage(Group group) async {
    try {
      final imageFile = await _storageService.pickImage(ImageSource.gallery);
      if (imageFile != null) {
        final croppedFile = await _storageService.cropImage(imageFile, context);
        if (croppedFile != null) {
          setState(() => _isLoading = true);

          // Create a method in your StorageService for uploading group images
          final imageUrl = await _storageService.uploadGroupImage(croppedFile);

          await _groupService.updateGroupInfo(
            groupId: widget.groupId,
            imageUrl: imageUrl,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Group image updated')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update group image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddMembersDialog(Group group) async {
    try {
      final users = await _groupService.getUsersNotInGroup(widget.groupId);

      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AddMembersDialog(
                groupId: widget.groupId,
                availableUsers: users,
              ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load users: $e')));
    }
  }

  void _showRemoveMemberDialog(Group group, ChattyUser user) {
    final currentUserId = _auth.currentUser?.uid;
    final isCurrentUser = user.uid == currentUserId;
    final isAdmin = group.isUserAdmin(currentUserId ?? '');
    final isMemberAdmin = group.isUserAdmin(user.uid);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isCurrentUser ? 'Leave Group' : 'Remove Member'),
            content: Text(
              isCurrentUser
                  ? 'Are you sure you want to leave this group?'
                  : 'Are you sure you want to remove ${user.username} from this group?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  try {
                    setState(() => _isLoading = true);

                    await _groupService.removeMemberFromGroup(
                      widget.groupId,
                      user.uid,
                    );

                    if (isCurrentUser && mounted) {
                      Navigator.pop(context); // Go back to home
                    }

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isCurrentUser
                                ? 'You left the group'
                                : '${user.username} removed from group',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(isCurrentUser ? 'Leave' : 'Remove'),
              ),
            ],
          ),
    );
  }

  void _toggleAdminStatus(Group group, ChattyUser user) async {
    final isAdmin = group.isUserAdmin(user.uid);

    try {
      setState(() => _isLoading = true);

      if (isAdmin) {
        await _groupService.removeAdminStatus(widget.groupId, user.uid);
      } else {
        await _groupService.makeUserAdmin(widget.groupId, user.uid);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAdmin
                  ? '${user.username} is no longer an admin'
                  : '${user.username} is now an admin',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
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
    final currentUserId = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Info'),
        actions: [
          StreamBuilder<Group?>(
            stream: _groupService.getGroupById(widget.groupId),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final group = snapshot.data!;
                final isAdmin = group.isUserAdmin(currentUserId ?? '');

                if (isAdmin) {
                  return IconButton(
                    icon: Icon(_isEditing ? Icons.check : Icons.edit),
                    onPressed: () {
                      if (_isEditing) {
                        _saveChanges(group);
                      } else {
                        _nameController.text = group.name;
                        _descriptionController.text = group.description ?? '';
                        _toggleEdit();
                      }
                    },
                  );
                }
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<Group?>(
                stream: _groupService.getGroupById(widget.groupId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data == null) {
                    return Center(
                      child: Text(
                        'Failed to load group: ${snapshot.error ?? "Group not found"}',
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }

                  final group = snapshot.data!;
                  final isAdmin = group.isUserAdmin(currentUserId ?? '');

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Group image and info
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap:
                                    isAdmin
                                        ? () => _changeGroupImage(group)
                                        : null,
                                child: Stack(
                                  children: [
                                    ProfileImage(
                                      imageUrl: group.imageUrl,
                                      fallbackText: group.name,
                                      size: 120,
                                    ),
                                    if (isAdmin)
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

                              if (_isEditing) ...[
                                // Editable fields
                                TextField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Group Name',
                                    border: OutlineInputBorder(),
                                  ),
                                  style: theme.textTheme.titleLarge,
                                ),

                                const SizedBox(height: 8),

                                TextField(
                                  controller: _descriptionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Description',
                                    border: OutlineInputBorder(),
                                  ),
                                  style: theme.textTheme.bodyMedium,
                                  maxLines: 3,
                                ),
                              ] else ...[
                                // Display fields
                                Text(
                                  group.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                if (group.description != null &&
                                    group.description!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      group.description!,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.7),
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              ],

                              const SizedBox(height: 8),

                              Text(
                                'Created on ${DateFormat('MMM d, yyyy').format(group.createdAt.toDate())}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Members section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Members (${group.members.length})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isAdmin)
                              ElevatedButton.icon(
                                onPressed: () => _showAddMembersDialog(group),
                                icon: const Icon(Icons.person_add),
                                label: const Text('Add'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Members list
                        FutureBuilder<List<ChattyUser>>(
                          future: Future.wait(
                            group.members.map((memberId) async {
                              final doc =
                                  await FirebaseFirestore.instance
                                      .collection('Users')
                                      .doc(memberId)
                                      .get();

                              if (doc.exists) {
                                return ChattyUser.fromMap(doc.data()!);
                              }

                              // Return a dummy user if not found
                              return ChattyUser(
                                uid: memberId,
                                email: 'Unknown',
                                username: 'Unknown User',
                                isVerified: false,
                              );
                            }),
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Failed to load members: ${snapshot.error}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              );
                            }

                            final members = snapshot.data ?? [];

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: members.length,
                              itemBuilder: (context, index) {
                                final member = members[index];
                                final isMemberAdmin = group.isUserAdmin(
                                  member.uid,
                                );
                                final isCurrentUser =
                                    member.uid == currentUserId;

                                return ListTile(
                                  leading: ProfileImage(
                                    imageUrl: member.profileImageUrl,
                                    fallbackText: member.username,
                                    size: 40,
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        member.username,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                      if (isCurrentUser)
                                        Text(
                                          ' (You)',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.7),
                                              ),
                                        ),
                                      if (isMemberAdmin)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            'Admin',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    member.email,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                  trailing:
                                      isAdmin &&
                                              (!isCurrentUser ||
                                                  group.admins.length > 1)
                                          ? PopupMenuButton(
                                            itemBuilder:
                                                (context) => [
                                                  PopupMenuItem(
                                                    value: 'toggle_admin',
                                                    child: ListTile(
                                                      leading: Icon(
                                                        isMemberAdmin
                                                            ? Icons.person
                                                            : Icons
                                                                .admin_panel_settings,
                                                        color:
                                                            theme
                                                                .colorScheme
                                                                .primary,
                                                      ),
                                                      title: Text(
                                                        isMemberAdmin
                                                            ? 'Remove Admin'
                                                            : 'Make Admin',
                                                        style:
                                                            theme
                                                                .textTheme
                                                                .titleSmall,
                                                      ),
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'remove',
                                                    child: ListTile(
                                                      leading: const Icon(
                                                        Icons
                                                            .remove_circle_outline,
                                                        color: Colors.red,
                                                      ),
                                                      title: Text(
                                                        'Remove',
                                                        style: theme
                                                            .textTheme
                                                            .titleSmall
                                                            ?.copyWith(
                                                              color: Colors.red,
                                                            ),
                                                      ),
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                    ),
                                                  ),
                                                ],
                                            onSelected: (value) {
                                              if (value == 'toggle_admin') {
                                                _toggleAdminStatus(
                                                  group,
                                                  member,
                                                );
                                              } else if (value == 'remove') {
                                                _showRemoveMemberDialog(
                                                  group,
                                                  member,
                                                );
                                              }
                                            },
                                          )
                                          : null,
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Leave group button
                        Center(
                          child: TextButton.icon(
                            onPressed:
                                () => _showRemoveMemberDialog(
                                  group,
                                  ChattyUser(
                                    uid: currentUserId ?? '',
                                    email: _auth.currentUser?.email ?? '',
                                    username: 'You',
                                    isVerified: false,
                                  ),
                                ),
                            icon: const Icon(
                              Icons.exit_to_app,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Leave Group',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}

// Add Members Dialog
class AddMembersDialog extends StatefulWidget {
  final String groupId;
  final List<ChattyUser> availableUsers;

  const AddMembersDialog({
    Key? key,
    required this.groupId,
    required this.availableUsers,
  }) : super(key: key);

  @override
  State<AddMembersDialog> createState() => _AddMembersDialogState();
}

class _AddMembersDialogState extends State<AddMembersDialog> {
  final GroupService _groupService = GroupService();
  final TextEditingController _searchController = TextEditingController();
  List<ChattyUser> _filteredUsers = [];
  List<String> _selectedUserIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _filteredUsers = List.from(widget.availableUsers);
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(widget.availableUsers);
      } else {
        _filteredUsers =
            widget.availableUsers
                .where(
                  (user) =>
                      user.username.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      user.email.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  void _addSelectedMembers() async {
    if (_selectedUserIds.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _groupService.addMembersToGroup(widget.groupId, _selectedUserIds);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Members added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add members: $e')));
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

    return AlertDialog(
      title: const Text('Add Members'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterUsers,
            ),

            const SizedBox(height: 16),

            Expanded(
              child:
                  _filteredUsers.isEmpty
                      ? Center(
                        child: Text(
                          'No users available',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                      : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final isSelected = _selectedUserIds.contains(
                            user.uid,
                          );

                          return ListTile(
                            leading: ProfileImage(
                              imageUrl: user.profileImageUrl,
                              fallbackText: user.username,
                              size: 40,
                            ),
                            title: Text(user.username),
                            subtitle: Text(user.email),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleUserSelection(user.uid),
                            ),
                            onTap: () => _toggleUserSelection(user.uid),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addSelectedMembers,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(
                    'Add ${_selectedUserIds.isEmpty ? "Selected" : _selectedUserIds.length} Members',
                  ),
        ),
      ],
    );
  }
}
