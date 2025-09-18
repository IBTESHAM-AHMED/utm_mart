import 'package:flutter/material.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/core/enums/status.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/features/auth/data/data_sources/firebase_auth_service.dart';
import 'package:utmmart/features/shop/data/models/store_item_model.dart';
import 'package:utmmart/features/shop/data/services/cart_service.dart';

class StoreItemDetailView extends StatefulWidget {
  final StoreItemModel item;

  const StoreItemDetailView({super.key, required this.item});

  @override
  State<StoreItemDetailView> createState() => _StoreItemDetailViewState();
}

class _StoreItemDetailViewState extends State<StoreItemDetailView> {
  final FirebaseAuthService _authService = sl<FirebaseAuthService>();
  final CartService _cartService = sl<CartService>();
  int _quantity = 1;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final result = await _authService.getCurrentUserDocument();
    result.fold((error) => print('Error loading current user: $error'), (user) {
      if (mounted) {
        setState(() {
          _currentUserId = user.uid;
        });
      }
    });
  }

  bool get _isCurrentUserSeller => _currentUserId == widget.item.sellerUid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          title: Text(widget.item.itemName),
          hasArrowBack: true,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            _buildProductImage(),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Price
                  _buildProductHeader(),

                  const SizedBox(height: TSizes.spaceBtwItems),

                  // Brand and Category
                  _buildProductMeta(),

                  const SizedBox(height: TSizes.spaceBtwItems),

                  // Full Description
                  _buildProductDescription(),

                  const SizedBox(height: TSizes.spaceBtwItems),

                  // Stock Information
                  _buildStockInfo(),

                  const SizedBox(height: TSizes.spaceBtwSections),

                  // Quantity Selector and Add to Cart (only if not seller)
                  if (!_isCurrentUserSeller) _buildCartSection(),

                  // Seller indicator (if current user is seller)
                  if (_isCurrentUserSeller) _buildSellerIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(color: TColors.grey.withOpacity(0.1)),
      child: widget.item.itemImageUrl.isNotEmpty
          ? Image.network(
              widget.item.itemImageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 300,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: TColors.grey.withOpacity(0.1),
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: TColors.grey.withOpacity(0.1),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 64, color: TColors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Image not available',
                          style: TextStyle(color: TColors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: TColors.grey,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No image available',
                    style: TextStyle(color: TColors.grey),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProductHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.item.itemName,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          widget.item.displayPrice,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: TColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProductMeta() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: TColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Brand: ${widget.item.itemBrand}',
              style: TextStyle(
                color: TColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: TColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.item.itemCategory,
            style: TextStyle(
              color: TColors.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TColors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TColors.grey.withOpacity(0.2)),
          ),
          child: Text(
            widget.item.itemDescription,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: TColors.dark, height: 1.6),
          ),
        ),
      ],
    );
  }

  Widget _buildStockInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.item.itemStock > 0
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.item.itemStock > 0
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.item.itemStock > 0 ? Icons.check_circle : Icons.error,
            color: widget.item.itemStock > 0 ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.itemStock > 0 ? 'In Stock' : 'Out of Stock',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.item.itemStock > 0
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                Text(
                  '${widget.item.itemStock} units available',
                  style: TextStyle(
                    color: widget.item.itemStock > 0
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSection() {
    return Column(
      children: [
        // Quantity Selector
        Row(
          children: [
            Text(
              'Quantity:',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: TColors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    icon: const Icon(Icons.remove),
                    color: _quantity > 1 ? TColors.primary : TColors.grey,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _quantity.toString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _quantity < widget.item.itemStock
                        ? () => setState(() => _quantity++)
                        : null,
                    icon: const Icon(Icons.add),
                    color: _quantity < widget.item.itemStock
                        ? TColors.primary
                        : TColors.grey,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: TSizes.spaceBtwItems),

        // Total Price
        Row(
          children: [
            Text('Total: ', style: Theme.of(context).textTheme.titleMedium),
            Text(
              'RM${(widget.item.itemPrice * _quantity).toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: TColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: TSizes.spaceBtwItems),

        // Add to Cart Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.item.itemStock > 0 ? _addToCart : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              widget.item.itemStock > 0
                  ? 'Add to Cart - RM${(widget.item.itemPrice * _quantity).toStringAsFixed(2)}'
                  : 'Out of Stock',
              style: const TextStyle(
                color: TColors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSellerIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.store, color: TColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Product',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: TColors.primary,
                  ),
                ),
                Text(
                  'You are the seller of this item',
                  style: TextStyle(color: TColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart() async {
    final success = await _cartService.addToCart(widget.item, _quantity);

    if (success) {
      THelperFunctions.showSnackBar(
        context: context,
        message: 'Added ${_quantity}x ${widget.item.itemName} to cart!',
        type: SnackBarType.success,
      );

      // Navigate back to store
      Navigator.of(context).pop();
    } else {
      THelperFunctions.showSnackBar(
        context: context,
        message: 'Failed to add item to cart. Please try again.',
        type: SnackBarType.error,
      );
    }
  }
}
