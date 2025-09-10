import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
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

class CreateAuctionView extends StatefulWidget {
  const CreateAuctionView({super.key});

  @override
  State<CreateAuctionView> createState() => _CreateAuctionViewState();
}

class _CreateAuctionViewState extends State<CreateAuctionView> {
  final AuctionFirestoreService _auctionService = sl<AuctionFirestoreService>();
  final FirebaseAuthService _authService = sl<FirebaseAuthService>();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _startingPriceController = TextEditingController();
  final _buyNowPriceController = TextEditingController();

  String _selectedCategory = 'Electronics';
  DateTime _endTime = DateTime.now().add(const Duration(days: 7));
  FirestoreUserModel? _currentUser;
  bool _isLoading = false;

  final List<String> _categories = [
    'Electronics',
    'Clothing',
    'Books',
    'Home',
    'Sports',
    'Beauty',
    'Art',
    'Collectibles',
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
    _imageUrlController.dispose();
    _startingPriceController.dispose();
    _buyNowPriceController.dispose();
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

  Future<void> _createAuction() async {
    if (!_formKey.currentState!.validate() || _currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final auction = AuctionModel(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        category: _selectedCategory,
        sellerUid: _currentUser!.uid,
        sellerName: _currentUser!.fullName,
        startingPrice: double.parse(_startingPriceController.text),
        currentBid: double.parse(_startingPriceController.text),
        buyNowPrice: _buyNowPriceController.text.isNotEmpty
            ? double.parse(_buyNowPriceController.text)
            : null,
        startTime: DateTime.now(),
        endTime: _endTime,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _auctionService.createAuction(auction);

      if (mounted) {
        THelperFunctions.showSnackBar(
          context: context,
          message: 'Auction created successfully!',
          type: SnackBarType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        THelperFunctions.showSnackBar(
          context: context,
          message: 'Error creating auction: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

              // Image URL
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'https://example.com/image.jpg',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an image URL';
                  }
                  return null;
                },
              ),
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

              // Buy Now Price (Optional)
              TextFormField(
                controller: _buyNowPriceController,
                decoration: const InputDecoration(
                  labelText: 'Buy Now Price (\$) - Optional',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid price';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Price must be greater than 0';
                    }
                    if (double.parse(value) <=
                        double.parse(_startingPriceController.text)) {
                      return 'Buy now price must be higher than starting price';
                    }
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
                  onPressed: _isLoading ? null : _createAuction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    padding: const EdgeInsets.symmetric(
                      vertical: TSizes.buttonHeight,
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Auction',
                          style: TextStyle(color: Colors.white),
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
