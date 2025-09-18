import 'package:flutter/material.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/core/enums/status.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/features/shop/data/models/cart_item_model.dart';
import 'package:utmmart/features/shop/data/services/cart_service.dart';
import 'package:utmmart/features/shop/presentation/views/order_confirmation_view.dart';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  final CartService _cartService = sl<CartService>();
  List<CartItemModel> _cartItems = [];
  bool _isLoading = true;
  double _cartTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    setState(() => _isLoading = true);

    final items = await _cartService.getCartItems();
    final total = await _cartService.getCartTotal();

    if (mounted) {
      setState(() {
        _cartItems = items;
        _cartTotal = total;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          title: Text(
            "Cart (${_cartItems.length})",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          hasArrowBack: true,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
          ? _buildEmptyCart()
          : _buildCartList(),
      bottomNavigationBar: _cartItems.isNotEmpty
          ? _buildCheckoutButton()
          : null,
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: TColors.grey),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: TColors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items from the store to get started',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: TColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    return ListView.builder(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      itemCount: _cartItems.length,
      itemBuilder: (context, index) {
        return _buildCartItemCard(_cartItems[index]);
      },
    );
  }

  Widget _buildCartItemCard(CartItemModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Item Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: TColors.grey.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.itemImageUrl.isNotEmpty
                    ? Image.network(
                        item.itemImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: TColors.grey.withOpacity(0.1),
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 24,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: TColors.grey.withOpacity(0.1),
                        child: const Icon(Icons.image, size: 24),
                      ),
              ),
            ),

            const SizedBox(width: 12),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${item.itemBrand} • ${item.itemCategory}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: TColors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.displayTotalPrice,
                    style: TextStyle(
                      color: TColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity Controls
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: TColors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () =>
                            _updateQuantity(item, item.quantity - 1),
                        icon: const Icon(Icons.remove, size: 16),
                        color: TColors.primary,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          item.quantity.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _updateQuantity(item, item.quantity + 1),
                        icon: const Icon(Icons.add, size: 16),
                        color: TColors.primary,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => _removeItem(item),
                  child: Text(
                    'Remove',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Padding(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cart Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total (${_cartItems.length} items):',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'RM${_cartTotal.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: TColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Checkout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _proceedToCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Proceed to Checkout - RM${_cartTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: TColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateQuantity(CartItemModel item, int newQuantity) async {
    if (newQuantity <= 0) {
      await _removeItem(item);
      return;
    }

    final success = await _cartService.updateQuantity(item.itemId, newQuantity);
    if (success) {
      _loadCartItems(); // Refresh cart
    } else {
      THelperFunctions.showSnackBar(
        context: context,
        message: 'Failed to update quantity',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _removeItem(CartItemModel item) async {
    final success = await _cartService.removeFromCart(item.itemId);
    if (success) {
      THelperFunctions.showSnackBar(
        context: context,
        message: '${item.itemName} removed from cart',
        type: SnackBarType.success,
      );
      _loadCartItems(); // Refresh cart
    } else {
      THelperFunctions.showSnackBar(
        context: context,
        message: 'Failed to remove item',
        type: SnackBarType.error,
      );
    }
  }

  void _proceedToCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderConfirmationView(cartItems: _cartItems),
      ),
    );
  }
}
