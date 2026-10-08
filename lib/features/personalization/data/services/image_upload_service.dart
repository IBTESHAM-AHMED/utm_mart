import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageUploadService {
  /// Uploads an image to ImgBB and returns the URL
  /// Returns null if upload fails
  Future<String?> uploadImage(File imageFile) async {
    // Use the fallback method that tries multiple services
    return await uploadImageWithFallback(imageFile);
  }

  /// Alternative method using Cloudinary (another free option)
  /// Uncomment and configure if you prefer Cloudinary
  /*
  static const String _cloudinaryCloudName = 'YOUR_CLOUD_NAME';
  static const String _cloudinaryUploadPreset = 'YOUR_UPLOAD_PRESET';
  
  Future<String?> uploadToCloudinary(File imageFile) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload');
      
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = _cloudinaryUploadPreset;
      request.fields['folder'] = 'profile_pictures';
      
      final multipartFile = await http.MultipartFile.fromPath('file', imageFile.path);
      request.files.add(multipartFile);
      
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final responseData = json.decode(responseBody);
        return responseData['secure_url'];
      } else {
        debugPrint('Cloudinary upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      return null;
    }
  }
  */

  /// Upload to PostImage.org (free, no API key required)
  Future<String?> uploadToPostImage(File imageFile) async {
    try {
      debugPrint('PostImage: Starting upload...');
      final uri = Uri.parse('https://postimages.org/');

      final request = http.MultipartRequest('POST', uri);
      request.fields['upload'] = 'Upload It!';
      request.fields['adult'] = 'no';
      request.fields['optsize'] = '0';
      request.fields['expire'] = '0';

      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      );
      request.files.add(multipartFile);

      final response = await request.send();
      debugPrint('PostImage: Response status ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();

        // PostImage returns HTML, we need to extract the direct image URL
        final RegExp urlRegex = RegExp(r'https://i\.postimg\.cc/[^"]+');
        final match = urlRegex.firstMatch(responseBody);

        if (match != null) {
          final imageUrl = match.group(0);
          debugPrint('PostImage: Found URL: $imageUrl');
          return imageUrl;
        } else {
          debugPrint('PostImage: Could not extract URL from response');
          return null;
        }
      } else {
        debugPrint('PostImage HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('PostImage upload error: $e');
      return null;
    }
  }

  /// Upload to ImgBB.com (free with API key)
  Future<String?> uploadToImgBB(File imageFile) async {
    try {
      debugPrint('ImgBB: Starting upload...');

      // You can get a free API key from https://api.imgbb.com/
      const String apiKey = 'bdb5c5d0c9d8f4f5e8c1d5c8f0e5c8f0'; // Free demo key

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'image': base64Image,
          'name': 'profile_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      debugPrint('ImgBB: Response status ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final imageUrl = responseData['data']['url'];
          debugPrint('ImgBB: Upload successful: $imageUrl');
          return imageUrl;
        } else {
          debugPrint('ImgBB API error: ${responseData['error']['message']}');
          return null;
        }
      } else {
        debugPrint('ImgBB HTTP error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('ImgBB upload error: $e');
      return null;
    }
  }

  /// Upload to Imgur.com (free, no API key required for anonymous uploads)
  Future<String?> uploadToImgur(File imageFile) async {
    try {
      debugPrint('Imgur: Starting upload...');

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final uri = Uri.parse('https://api.imgur.com/3/image');

      final response = await http.post(
        uri,
        headers: {
          'Authorization':
              'Client-ID 546c25a59c58ad7', // Anonymous upload client ID
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'image': base64Image, 'type': 'base64'},
      );

      debugPrint('Imgur: Response status ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final imageUrl = responseData['data']['link'];
          debugPrint('Imgur: Upload successful: $imageUrl');
          return imageUrl;
        } else {
          debugPrint('Imgur API error: ${responseData['data']['error']}');
          return null;
        }
      } else {
        debugPrint('Imgur HTTP error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Imgur upload error: $e');
      return null;
    }
  }

  /// Fallback method using a simple free image hosting service
  /// This uses freeimage.host which doesn't require API key
  Future<String?> uploadToFreeImageHost(File imageFile) async {
    try {
      debugPrint('FreeImage.host: Starting upload...');
      final uri = Uri.parse('https://freeimage.host/api/1/upload');

      final request = http.MultipartRequest('POST', uri);
      request.fields['format'] = 'json';

      final multipartFile = await http.MultipartFile.fromPath(
        'source',
        imageFile.path,
      );
      request.files.add(multipartFile);

      final response = await request.send();
      debugPrint('FreeImage.host: Response status ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        debugPrint('FreeImage.host: Response body: $responseBody');
        final responseData = json.decode(responseBody);

        if (responseData['status_code'] == 200) {
          final imageUrl = responseData['image']['url'];
          debugPrint('FreeImage.host: Upload successful: $imageUrl');
          return imageUrl;
        } else {
          debugPrint('FreeImage.host error: ${responseData['error']['message']}');
          return null;
        }
      } else {
        debugPrint('FreeImage.host HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('FreeImage.host upload error: $e');
      return null;
    }
  }

  /// Main upload method that tries multiple services as fallbacks
  Future<String?> uploadImageWithFallback(File imageFile) async {
    debugPrint('Starting image upload with fallback...');

    // Try Imgur first (most reliable, no API key required)
    debugPrint('Trying Imgur...');
    final imgurUrl = await uploadToImgur(imageFile);
    if (imgurUrl != null) {
      debugPrint('Imgur upload successful: $imgurUrl');
      return imgurUrl;
    }

    // Try ImgBB with demo API key
    debugPrint('Trying ImgBB...');
    final imgbbUrl = await uploadToImgBB(imageFile);
    if (imgbbUrl != null) {
      debugPrint('ImgBB upload successful: $imgbbUrl');
      return imgbbUrl;
    }

    // Try FreeImage.host
    debugPrint('Trying FreeImage.host...');
    final freeHostUrl = await uploadToFreeImageHost(imageFile);
    if (freeHostUrl != null) {
      debugPrint('FreeImage.host upload successful: $freeHostUrl');
      return freeHostUrl;
    }

    // Try PostImage.org as last option
    debugPrint('Trying PostImage.org...');
    final postImageUrl = await uploadToPostImage(imageFile);
    if (postImageUrl != null) {
      debugPrint('PostImage.org upload successful: $postImageUrl');
      return postImageUrl;
    }

    debugPrint('All upload methods failed');
    return null;
  }
}
