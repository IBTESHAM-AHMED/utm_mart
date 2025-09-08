import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/core/enums/status.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/features/auth/data/data_sources/firebase_auth_service.dart';
import 'package:utmmart/features/personalization/data/services/image_upload_service.dart';

class ChangeProfilePictureView extends StatefulWidget {
  const ChangeProfilePictureView({super.key});

  @override
  State<ChangeProfilePictureView> createState() =>
      _ChangeProfilePictureViewState();
}

class _ChangeProfilePictureViewState extends State<ChangeProfilePictureView> {
  final FirebaseAuthService _authService = sl<FirebaseAuthService>();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isUploading = false;
  String? _currentProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfileImage();
  }

  Future<void> _loadCurrentProfileImage() async {
    final result = await _authService.getCurrentUserDocument();
    result.fold(
      (error) {
        print('Error loading current profile: $error');
      },
      (user) {
        if (mounted) {
          setState(() {
            _currentProfileImageUrl = user.profileImageUrl.isNotEmpty
                ? user.profileImageUrl
                : null;
          });
        }
      },
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      THelperFunctions.showSnackBar(
        context: context,
        message: 'Failed to pick image: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) {
      THelperFunctions.showSnackBar(
        context: context,
        message: 'Please select an image first',
        type: SnackBarType.warning,
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      print('Starting image upload process...');

      // Upload image to free hosting service
      final imageUrl = await _imageUploadService.uploadImage(_selectedImage!);
      print('Upload result: $imageUrl');

      if (imageUrl != null) {
        print('Image uploaded successfully, updating user profile...');

        // Update user profile with new image URL
        final result = await _authService.updateCurrentUserDocument({
          'profileImageUrl': imageUrl,
        });

        result.fold(
          (error) {
            print('Failed to update profile in Firestore: $error');
            THelperFunctions.showSnackBar(
              context: context,
              message: 'Failed to update profile: $error',
              type: SnackBarType.error,
            );
          },
          (_) {
            print('Profile updated successfully in Firestore');
            THelperFunctions.showSnackBar(
              context: context,
              message: 'Profile picture updated successfully!',
              type: SnackBarType.success,
            );

            setState(() {
              _currentProfileImageUrl = imageUrl;
              _selectedImage = null;
            });

            // Go back to profile page after successful upload
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                Navigator.of(
                  context,
                ).pop(true); // Return true to indicate success
              }
            });
          },
        );
      } else {
        print('All image upload services failed');
        THelperFunctions.showSnackBar(
          context: context,
          message:
              'Failed to upload image. All hosting services are currently unavailable. Please try again later.',
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      print('Upload process error: $e');
      THelperFunctions.showSnackBar(
        context: context,
        message: 'Upload failed: ${e.toString()}',
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          title: const Text("Change Profile Picture"),
          hasArrowBack: true,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              const SizedBox(height: TSizes.spaceBtwSections),

              // Current/Selected Image Display
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: TColors.grey, width: 2),
                      ),
                      child: ClipOval(
                        child: _selectedImage != null
                            ? Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: 200,
                                height: 200,
                              )
                            : _currentProfileImageUrl != null
                            ? Image.network(
                                _currentProfileImageUrl!,
                                fit: BoxFit.cover,
                                width: 200,
                                height: 200,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    size: 80,
                                    color: TColors.grey,
                                  );
                                },
                              )
                            : const Icon(
                                Icons.person,
                                size: 80,
                                color: TColors.grey,
                              ),
                      ),
                    ),

                    // Upload Icon Overlay
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: _isUploading ? null : _pickImage,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: TColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: TColors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: TColors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              // Instructions
              Text(
                _selectedImage != null
                    ? 'Tap "Upload" to save your new profile picture'
                    : 'Tap the camera icon to select a new profile picture',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: TColors.grey),
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              // Upload Button
              if (_selectedImage != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _uploadImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: _isUploading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: TColors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Uploading...',
                                style: TextStyle(color: TColors.white),
                              ),
                            ],
                          )
                        : const Text(
                            'Upload Picture',
                            style: TextStyle(color: TColors.white),
                          ),
                  ),
                ),

              const Spacer(),

              // Info Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TColors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: TColors.primary, size: 24),
                    const SizedBox(height: 8),
                    Text(
                      'Your image will be uploaded to a secure server and the URL will be saved in your profile.',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: TColors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
