import 'package:flutter/material.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/core/enums/status.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/features/auth/data/data_sources/firebase_auth_service.dart';
import 'package:utmmart/features/shop/data/models/cart_item_model.dart';
import 'package:utmmart/features/shop/data/services/cart_service.dart';
import 'package:utmmart/features/shop/data/services/order_service.dart';

class OrderConfirmationView extends StatefulWidget {
  final List<CartItemModel> cartItems;

  const OrderConfirmationView({super.key, required this.cartItems});

  @override
  State<OrderConfirmationView> createState() => _OrderConfirmationViewState();
}

class _OrderConfirmationViewState extends State<OrderConfirmationView> {
  final FirebaseAuthService _authService = sl<FirebaseAuthService>();
  final CartService _cartService = sl<CartService>();
  final OrderService _orderService = OrderService();

  bool _isProcessing = false;
  double _subtotal = 0.0;
  double _tax = 0.0;
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateTotals();
  }

  void _calculateTotals() {
    _subtotal = widget.cartItems.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
    _tax = _subtotal * 0.08; // 8% tax
    _total = _subtotal + _tax;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          title: const Text("Order Confirmation"),
          hasArrowBack: true,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Items
            _buildOrderItems(),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Order Summary
            _buildOrderSummary(),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Confirm Button
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Items',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...widget.cartItems.map((item) => _buildOrderItemCard(item)),
      ],
    );
  }

  Widget _buildOrderItemCard(CartItemModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Item Image
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: TColors.grey.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: item.itemImageUrl.isNotEmpty
                    ? Image.network(
                        item.itemImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: TColors.grey.withOpacity(0.1),
                            child: const Icon(Icons.image, size: 20),
                          );
                        },
                      )
                    : Container(
                        color: TColors.grey.withOpacity(0.1),
                        child: const Icon(Icons.image, size: 20),
                      ),
              ),
            ),

            const SizedBox(width: 12),

            // Item Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemName,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${item.itemBrand} • Qty: ${item.quantity}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: TColors.grey),
                  ),
                ],
              ),
            ),

            // Price
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
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Subtotal', '\$${_subtotal.toStringAsFixed(2)}'),
          _buildSummaryRow('Tax (8%)', '\$${_tax.toStringAsFixed(2)}'),
          const Divider(),
          _buildSummaryRow(
            'Total',
            '\$${_total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? TColors.primary : null,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTotal ? TColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _confirmOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: TColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isProcessing
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
                  SizedBox(width: 12),
                  Text(
                    'Processing Order...',
                    style: TextStyle(color: TColors.white),
                  ),
                ],
              )
            : Text(
                'Confirm Order - \$${_total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: TColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _confirmOrder() async {
    setState(() => _isProcessing = true);

    try {
      // Get current user
      final userResult = await _authService.getCurrentUserDocument();
      final currentUser = userResult.fold((error) => null, (user) => user);

      if (currentUser == null) {
        THelperFunctions.showSnackBar(
          context: context,
          message: 'Please login to place order',
          type: SnackBarType.error,
        );
        setState(() => _isProcessing = false);
        return;
      }

      // Create order
      final success = await _orderService.createOrder(
        cartItems: widget.cartItems,
        customer: currentUser,
        subtotal: _subtotal,
        tax: _tax,
        total: _total,
      );

      if (success) {
        // Clear cart after successful order
        await _cartService.clearCart();

        THelperFunctions.showSnackBar(
          context: context,
          message: 'Order placed successfully!',
          type: SnackBarType.success,
        );

        // Navigate back to store
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        THelperFunctions.showSnackBar(
          context: context,
          message: 'Failed to place order. Please try again.',
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      THelperFunctions.showSnackBar(
        context: context,
        message: 'Error placing order: ${e.toString()}',
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
