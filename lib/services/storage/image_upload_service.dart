import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageUploadService {
  // Initialize environment variables
  static Future<void> initEnv() async {
    await dotenv.load(fileName: ".env");
  }
  // Use ImgBB free API (get API key from https://api.imgbb.com/)
  // Note: Free plan has limitations, for production use a paid plan or alternative
  static String apiKey = dotenv.env['IMAGE_API_KEY'] ?? '';
  static const String apiUrl = 'https://api.imgbb.com/1/upload';

  // Pick image from gallery or camera
  Future<File?> pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 500,
        maxHeight: 500,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      print("Error picking image: $e");
      return null;
    }
  }

  // Upload image to ImgBB
  Future<String?> uploadImage(File imageFile) async {
    try {
      // Compress image before uploading
      final bytes = await imageFile.readAsBytes();

      // Convert image to base64
      final base64Image = base64Encode(bytes);

      // Create request
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        body: {'image': base64Image},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          // Return direct image URL
          return jsonResponse['data']['url'];
        }
      }

      throw Exception('Failed to upload image: ${response.body}');
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }

  // Alternative: Use a free avatar service with customization
  String generateCustomAvatar(String name, {String? style}) {
    final encodedName = Uri.encodeComponent(name);
    final styleParam = style != null ? '&style=$style' : '';

    // Using DiceBear Avatars - a free avatar web service
    return 'https://avatars.dicebear.com/api/initials/$encodedName.svg?background=%234169E1&color=%23ffffff$styleParam';
  }
}
