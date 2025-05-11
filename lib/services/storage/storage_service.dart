import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatty/services/storage/image_upload_service.dart';

class StorageService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageUploadService _imageUploadService = ImageUploadService();

  // Pick image from gallery or camera (still useful for UI)
  Future<File?> pickImage(ImageSource source) async {
    try {
      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 400,
        maxHeight: 400,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      print("Error picking image: $e");
      return null;
    }
  }

  // Generate a profile avatar URL based on user data
  String generateAvatarUrl(
    String? displayName,
    String? email, [
    String? colorHex,
  ]) {
    // Use display name if available, otherwise use email
    final String nameToUse =
        displayName?.isNotEmpty == true
            ? displayName!
            : (email?.split('@').first ?? 'User');

    // Create initials from the name (up to 2 characters)
    final String initials = nameToUse
        .split(' ')
        .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
        .take(2)
        .join('');

    // Default colors if none provided
    final String color = colorHex ?? _getRandomColor(nameToUse);

    // Build UI Avatars URL
    return 'https://ui-avatars.com/api/'
        '?name=${Uri.encodeComponent(initials)}'
        '&background=${color.replaceAll('#', '')}'
        '&color=ffffff'
        '&size=200'
        '&bold=true';
  }

  // Get a consistent "random" color based on a string
  String _getRandomColor(String input) {
    // Get a deterministic hash from the input string
    final int hash = input.codeUnits.fold(0, (prev, element) => prev + element);

    // List of good background colors (avoiding very light colors)
    final List<String> colors = [
      '2196F3', // Blue
      '4CAF50', // Green
      'FF9800', // Orange
      '9C27B0', // Purple
      'F44336', // Red
      '009688', // Teal
      '3F51B5', // Indigo
      '795548', // Brown
      '607D8B', // Blue Grey
    ];

    // Pick a color based on the hash
    return colors[hash % colors.length];
  }

  // "Upload" profile image - actually just updates the user's avatar color
  Future<String?> uploadProfileImage(File? file) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get current user data
      final userData = await _firestore.collection('Users').doc(user.uid).get();
      final username =
          userData.data()?['username'] ?? user.email?.split('@').first;

      String? avatarUrl;

      if (file != null) {
        // Upload file to ImgBB
        avatarUrl = await _imageUploadService.uploadImage(file);

        if (avatarUrl == null) {
          // Fallback to avatar generation if upload fails
          final randomColor = _getRandomColor(DateTime.now().toString());
          avatarUrl = generateAvatarUrl(username, user.email, randomColor);
        }
      } else {
        // Generate new avatar with random color
        final randomColor = _getRandomColor(DateTime.now().toString());
        avatarUrl = generateAvatarUrl(username, user.email, randomColor);
      }

      // Update user document with avatar URL
      await _firestore.collection('Users').doc(user.uid).update({
        'profileImageUrl': avatarUrl,
        'lastAvatarUpdate': FieldValue.serverTimestamp(),
      });

      return avatarUrl;
    } catch (e) {
      print("Profile image update failed with error: $e");
      throw Exception('Failed to update profile image: $e');
    }
  }

  // Delete profile image (reset to default avatar)
  Future<void> deleteProfileImage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get current user data
      final userData = await _firestore.collection('Users').doc(user.uid).get();
      final username =
          userData.data()?['username'] ?? user.email?.split('@').first;

      // Generate default avatar URL (without custom color)
      final String defaultAvatarUrl = generateAvatarUrl(username, user.email);

      // Update user document to use default avatar
      await _firestore.collection('Users').doc(user.uid).update({
        'profileImageUrl': defaultAvatarUrl,
        'lastAvatarUpdate': null,
      });
    } catch (e) {
      print("Error resetting profile image: $e");
      throw Exception('Failed to reset profile image: $e');
    }
  }

  Future<String> uploadGroupImage(File? file) async {
    try {
      // Get the group data to which we're adding the image
      final groupId =
          file?.path.split('/').last.split('_')[0] ??
          DateTime.now().millisecondsSinceEpoch.toString();

      // Get the group's name if available, otherwise use "Group"
      String groupName = "Group";
      try {
        final groupDoc =
            await FirebaseFirestore.instance
                .collection('groups')
                .doc(groupId)
                .get();

        if (groupDoc.exists) {
          groupName = groupDoc.data()?['name'] ?? "Group";
        }
      } catch (e) {
        print("Could not get group name: $e");
      }

      // Generate a random color for visual feedback
      final String randomColor = _getRandomColor(DateTime.now().toString());

      // Create an avatar URL for the group
      final String avatarUrl = generateAvatarUrl(groupName, null, randomColor);

      print("Generated group avatar URL: $avatarUrl");

      return avatarUrl;
    } catch (e) {
      print("Group avatar generation failed: $e");
      throw Exception('Failed to generate group avatar: $e');
    }
  }

  String? getRandomColor(String string) {
    // Get a deterministic hash from the input string
    final int hash = string.codeUnits.fold(
      0,
      (prev, element) => prev + element,
    );

    // List of good background colors (avoiding very light colors)
    final List<String> colors = [
      '2196F3', // Blue
      '4CAF50', // Green
      'FF9800', // Orange
      '9C27B0', // Purple
      'F44336', // Red
      '009688', // Teal
      '3F51B5', // Indigo
      '795548', // Brown
      '607D8B', // Blue Grey
    ];

    return colors[hash % colors.length];
  }
}
