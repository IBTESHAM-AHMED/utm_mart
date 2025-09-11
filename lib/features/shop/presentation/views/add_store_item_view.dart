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
import 'package:utmmart/features/shop/data/models/store_item_model.dart';
import 'package:utmmart/features/shop/data/services/store_firestore_service.dart';
import 'package:utmmart/features/personalization/data/services/image_upload_service.dart';

class AddStoreItemView extends StatefulWidget {
  const AddStoreItemView({super.key});

  @override
  State<AddStoreItemView> createState() => _AddStoreItemViewState();
}

class _AddStoreItemViewState extends State<AddStoreItemView> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuthService _authService = sl<FirebaseAuthService>();
  final StoreFirestoreService _storeService = sl<StoreFirestoreService>();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final ImagePicker _picker = ImagePicker();

  // Form controllers
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemDescriptionController =
      TextEditingController();
  final TextEditingController _itemPriceController = TextEditingController();
  final TextEditingController _itemStockController = TextEditingController();
  final TextEditingController _itemBrandController = TextEditingController();
  // Form variables
  String _selectedCategory = 'Electronics';
  File? _selectedImage;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Electronics',
    'Clothing',
    'Books',
    'Home',
    'Sports',
    'Beauty',
    'Vehicle',
    'Other',
  ];

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemDescriptionController.dispose();
    _itemPriceController.dispose();
    _itemStockController.dispose();
    _itemBrandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          title: const Text("Add New Item"),
          hasArrowBack: true,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Upload Section
                _buildImageSection(),

                const SizedBox(height: TSizes.spaceBtwSections),

                // Item Name
                TextFormField(
                  controller: _itemNameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    hintText: 'Enter item name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Item name is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: TSizes.spaceBtwInputFields),

                // Item Description
                TextFormField(
                  controller: _itemDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Item Description',
                    hintText: 'Describe your item',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Item description is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: TSizes.spaceBtwInputFields),

                // Price and Stock Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _itemPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Price (\$)',
                          hintText: '0.00',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Price is required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Enter valid price';
                          }
                          if (double.parse(value) <= 0) {
                            return 'Price must be greater than 0';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(width: TSizes.spaceBtwInputFields),

                    Expanded(
                      child: TextFormField(
                        controller: _itemStockController,
                        decoration: const InputDecoration(
                          labelText: 'Stock Quantity',
                          hintText: '0',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Stock is required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Enter valid number';
                          }
                          if (int.parse(value) < 0) {
                            return 'Stock cannot be negative';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: TSizes.spaceBtwInputFields),

                // Brand
                TextFormField(
                  controller: _itemBrandController,
                  decoration: const InputDecoration(
                    labelText: 'Brand',
                    hintText: 'Enter brand name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Brand is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: TSizes.spaceBtwInputFields),

                // Category
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),

                const SizedBox(height: TSizes.spaceBtwSections),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
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
                                'Adding Item...',
                                style: TextStyle(color: TColors.white),
                              ),
                            ],
                          )
                        : const Text(
                            'Add Item to Store',
                            style: TextStyle(color: TColors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  Future<void> _submitForm() async {
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

      // Create store item
      final storeItem = StoreItemModel.forSelling(
        itemImageUrl: imageUrl,
        itemName: _itemNameController.text.trim(),
        itemDescription: _itemDescriptionController.text.trim(),
        itemPrice: double.parse(_itemPriceController.text.trim()),
        itemStock: int.parse(_itemStockController.text.trim()),
        itemBrand: _itemBrandController.text.trim(),
        itemCategory: _selectedCategory,
        sellerUid: currentUser.uid,
      );

      // Add to Firestore
      final result = await _storeService.addStoreItem(storeItem);

      result.fold(
        (error) {
          THelperFunctions.showSnackBar(
            context: context,
            message: error,
            type: SnackBarType.error,
          );
        },
        (_) {
          THelperFunctions.showSnackBar(
            context: context,
            message: 'Item added to store successfully!',
            type: SnackBarType.success,
          );

          // Go back to store page
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        },
      );
    } catch (e) {
      THelperFunctions.showSnackBar(
        context: context,
        message: 'Failed to add item: ${e.toString()}',
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
