import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/enums/status.dart';
import 'package:utmmart/features/auction/data/models/auction_model.dart';
import 'package:utmmart/features/auction/data/services/auction_firestore_service.dart';
import 'package:utmmart/features/auth/data/data_sources/firebase_auth_service.dart';
import 'package:utmmart/features/auth/data/models/firestore_user_model.dart';
import 'package:utmmart/features/personalization/data/services/image_upload_service.dart';

class CreateAuctionView extends StatefulWidget {
  const CreateAuctionView({super.key});

  @override
  State<CreateAuctionView> createState() => _CreateAuctionViewState();
}

class _CreateAuctionViewState extends State<CreateAuctionView> {
  final AuctionFirestoreService _auctionService = sl<AuctionFirestoreService>();
  final FirebaseAuthService _authService = sl<FirebaseAuthService>();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final ImagePicker _imagePicker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startingPriceController = TextEditingController();

  String _selectedCategory = 'Electronics';
  DateTime _endTime = DateTime.now().add(const Duration(days: 7));
  FirestoreUserModel? _currentUser;
  bool _isSubmitting = false;
  File? _selectedImage;

  final List<String> _categories = [
    'Electronics',
    'Clothing',
    'Books',
    'Home',
    'Sports',
    'Beauty',
    'Art',
    'Collectibles',
    'Vehicle',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startingPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final result = await _authService.getCurrentUserDocument();
    result.fold(
      (error) {
        THelperFunctions.showSnackBar(
          context: context,
          message: 'Error loading user: $error',
          type: SnackBarType.error,
        );
      },
      (user) {
        setState(() {
          _currentUser = user;
        });
      },
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        THelperFunctions.showSnackBar(
          context: context,
          message: 'Error picking image: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Image',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 16),

        // Image Upload Option
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: TColors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 48,
                          color: TColors.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap to select image',
                          style: TextStyle(
                            color: TColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Required',
                          style: TextStyle(color: TColors.grey, fontSize: 12),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createAuction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Check if image is selected
      if (_selectedImage == null) {
        THelperFunctions.showSnackBar(
          context: context,
          message: 'Please select an image',
          type: SnackBarType.error,
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // Upload image
      final imageUrl = await _imageUploadService.uploadImage(_selectedImage!);
      if (imageUrl == null) {
        THelperFunctions.showSnackBar(
          context: context,
          message: 'Failed to upload image. Please try again.',
          type: SnackBarType.error,
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // Get current user
      final userResult = await _authService.getCurrentUserDocument();
      final currentUser = userResult.fold((error) => null, (user) => user);

      if (currentUser == null) {
        THelperFunctions.showSnackBar(
          context: context,
          message: 'User not found. Please login again.',
          type: SnackBarType.error,
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // Create auction
      final auction = AuctionModel(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
        category: _selectedCategory,
        sellerUid: currentUser.uid,
        sellerName: currentUser.fullName,
        startingPrice: double.parse(_startingPriceController.text.trim()),
        currentBid: double.parse(_startingPriceController.text.trim()),
        buyNowPrice: null, // Removed buy now price
        startTime: DateTime.now(),
        endTime: _endTime,
        status: 'active',
        bids: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to Firestore
      await _auctionService.createAuction(auction);

      THelperFunctions.showSnackBar(
        context: context,
        message: 'Auction created successfully!',
        type: SnackBarType.success,
      );

      // Go back to auction page
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    } catch (e) {
      THelperFunctions.showSnackBar(
        context: context,
        message: 'Failed to create auction: ${e.toString()}',
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          hasArrowBack: true,
          title: const Text('Create Auction'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Auction Title',
                  hintText: 'Enter a descriptive title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your item in detail',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              // Image Upload Section
              _buildImageSection(),
              const SizedBox(height: TSizes.spaceBtwItems),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              // Starting Price
              TextFormField(
                controller: _startingPriceController,
                decoration: const InputDecoration(
                  labelText: 'Starting Price (\$)',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a starting price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Price must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              // End Time
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endTime,
                    firstDate: DateTime.now().add(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_endTime),
                    );
                    if (time != null) {
                      setState(() {
                        _endTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Time',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Iconsax.calendar),
                  ),
                  child: Text(
                    '${_endTime.day}/${_endTime.month}/${_endTime.year} ${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              // Create Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _createAuction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isSubmitting
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
                              'Creating Auction...',
                              style: TextStyle(color: TColors.white),
                            ),
                          ],
                        )
                      : const Text(
                          'Create Auction',
                          style: TextStyle(color: TColors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
