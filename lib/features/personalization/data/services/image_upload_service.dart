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
        print('Cloudinary upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }
  */

  /// Upload to PostImage.org (free, no API key required)
  Future<String?> uploadToPostImage(File imageFile) async {
    try {
      print('PostImage: Starting upload...');
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
      print('PostImage: Response status ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();

        // PostImage returns HTML, we need to extract the direct image URL
        final RegExp urlRegex = RegExp(r'https://i\.postimg\.cc/[^"]+');
        final match = urlRegex.firstMatch(responseBody);

        if (match != null) {
          final imageUrl = match.group(0);
          print('PostImage: Found URL: $imageUrl');
          return imageUrl;
        } else {
          print('PostImage: Could not extract URL from response');
          return null;
        }
      } else {
        print('PostImage HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('PostImage upload error: $e');
      return null;
    }
  }

  /// Upload to ImgBB.com (free with API key)
  Future<String?> uploadToImgBB(File imageFile) async {
    try {
      print('ImgBB: Starting upload...');

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

      print('ImgBB: Response status ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final imageUrl = responseData['data']['url'];
          print('ImgBB: Upload successful: $imageUrl');
          return imageUrl;
        } else {
          print('ImgBB API error: ${responseData['error']['message']}');
          return null;
        }
      } else {
        print('ImgBB HTTP error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('ImgBB upload error: $e');
      return null;
    }
  }

  /// Upload to Imgur.com (free, no API key required for anonymous uploads)
  Future<String?> uploadToImgur(File imageFile) async {
    try {
      print('Imgur: Starting upload...');

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

      print('Imgur: Response status ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final imageUrl = responseData['data']['link'];
          print('Imgur: Upload successful: $imageUrl');
          return imageUrl;
        } else {
          print('Imgur API error: ${responseData['data']['error']}');
          return null;
        }
      } else {
        print('Imgur HTTP error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Imgur upload error: $e');
      return null;
    }
  }

  /// Fallback method using a simple free image hosting service
  /// This uses freeimage.host which doesn't require API key
  Future<String?> uploadToFreeImageHost(File imageFile) async {
    try {
      print('FreeImage.host: Starting upload...');
      final uri = Uri.parse('https://freeimage.host/api/1/upload');

      final request = http.MultipartRequest('POST', uri);
      request.fields['format'] = 'json';

      final multipartFile = await http.MultipartFile.fromPath(
        'source',
        imageFile.path,
      );
      request.files.add(multipartFile);

      final response = await request.send();
      print('FreeImage.host: Response status ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print('FreeImage.host: Response body: $responseBody');
        final responseData = json.decode(responseBody);

        if (responseData['status_code'] == 200) {
          final imageUrl = responseData['image']['url'];
          print('FreeImage.host: Upload successful: $imageUrl');
          return imageUrl;
        } else {
          print('FreeImage.host error: ${responseData['error']['message']}');
          return null;
        }
      } else {
        print('FreeImage.host HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('FreeImage.host upload error: $e');
      return null;
    }
  }

  /// Main upload method that tries multiple services as fallbacks
  Future<String?> uploadImageWithFallback(File imageFile) async {
    print('Starting image upload with fallback...');

    // Try Imgur first (most reliable, no API key required)
    print('Trying Imgur...');
    final imgurUrl = await uploadToImgur(imageFile);
    if (imgurUrl != null) {
      print('Imgur upload successful: $imgurUrl');
      return imgurUrl;
    }

    // Try ImgBB with demo API key
    print('Trying ImgBB...');
    final imgbbUrl = await uploadToImgBB(imageFile);
    if (imgbbUrl != null) {
      print('ImgBB upload successful: $imgbbUrl');
      return imgbbUrl;
    }

    // Try FreeImage.host
    print('Trying FreeImage.host...');
    final freeHostUrl = await uploadToFreeImageHost(imageFile);
    if (freeHostUrl != null) {
      print('FreeImage.host upload successful: $freeHostUrl');
      return freeHostUrl;
    }

    // Try PostImage.org as last option
    print('Trying PostImage.org...');
    final postImageUrl = await uploadToPostImage(imageFile);
    if (postImageUrl != null) {
      print('PostImage.org upload successful: $postImageUrl');
      return postImageUrl;
    }

    print('All upload methods failed');
    return null;
  }
}
