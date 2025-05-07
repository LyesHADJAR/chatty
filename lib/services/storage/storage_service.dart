import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Pick image from gallery or camera
  Future<File?> pickImage(ImageSource source) async {
    try {
      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Reduce image quality slightly for performance
      );

      if (image == null) return null;

      return File(image.path);
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Crop image
  Future<File?> cropImage(File imageFile, BuildContext context) async {
    try {
      final theme = Theme.of(context);

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 70,
        maxWidth: 500,
        maxHeight: 500,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: theme.colorScheme.primary,
            toolbarWidgetColor: theme.colorScheme.onPrimary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile == null) return null;

      return File(croppedFile.path);
    } catch (e) {
      throw Exception('Failed to crop image: $e');
    }
  }

  // Compress image
  Future<File?> compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/${path.basename(file.path)}';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: 70,
        minWidth: 500,
        minHeight: 500,
      );

      if (result == null) return file;

      return File(result.path);
    } catch (e) {
      print('Compression failed: $e');
      return file; // Return original if compression fails
    }
  }

  // Upload profile image
  Future<String> uploadProfileImage(File file) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Compress the image before uploading
      final compressedFile = await compressImage(file);

      // Create file reference
      final fileName =
          'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('profile_images').child(fileName);

      // Upload file
      await ref.putFile(compressedFile ?? file);

      // Get download URL
      final url = await ref.getDownloadURL();

      // Update user document
      await _firestore.collection('Users').doc(user.uid).update({
        'profileImageUrl': url,
      });

      return url;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete profile image
  Future<void> deleteProfileImage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get current profile image URL
      final doc = await _firestore.collection('Users').doc(user.uid).get();
      final imageUrl = doc.data()?['profileImageUrl'];

      if (imageUrl != null && imageUrl.isNotEmpty) {
        // Extract file name from URL and delete from storage
        try {
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          print('Failed to delete image from storage: $e');
          // Continue anyway to update the user document
        }
      }

      // Update user document
      await _firestore.collection('Users').doc(user.uid).update({
        'profileImageUrl': null,
      });
    } catch (e) {
      throw Exception('Failed to delete profile image: $e');
    }
  }

  // Download and cache profile image
  Future<File?> cacheProfileImage(String imageUrl) async {
    try {
      // Generate a file name based on the URL
      final fileName = 'cached_${path.basename(imageUrl)}';
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';

      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        return file;
      }

      // Download the image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      // Save to cache
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (e) {
      print('Failed to cache image: $e');
      return null;
    }
  }

  // Upload group image
  Future<String> uploadGroupImage(File file) async {
    try {
      // Compress the image before uploading
      final compressedFile = await compressImage(file);

      // Create file reference with a unique name
      final fileName = 'group_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('group_images').child(fileName);

      // Upload file
      await ref.putFile(compressedFile ?? file);

      // Get download URL
      final url = await ref.getDownloadURL();

      return url;
    } catch (e) {
      throw Exception('Failed to upload group image: $e');
    }
  }

  // Delete group image
  Future<void> deleteGroupImage(String imageUrl) async {
    try {
      // Extract file name from URL and delete from storage
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete group image: $e');
    }
  }
}
