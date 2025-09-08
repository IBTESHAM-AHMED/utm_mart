import 'package:flutter/material.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/features/shop/data/services/cart_service.dart';

class CartCounterWidget extends StatefulWidget {
  final VoidCallback onTap;
  final Color? iconColor;

  const CartCounterWidget({super.key, required this.onTap, this.iconColor});

  @override
  State<CartCounterWidget> createState() => _CartCounterWidgetState();
}

class _CartCounterWidgetState extends State<CartCounterWidget> {
  final CartService _cartService = sl<CartService>();
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCartCount();
  }

  Future<void> _loadCartCount() async {
    final count = await _cartService.getCartItemCount();
    if (mounted) {
      setState(() {
        _cartItemCount = count;
      });
    }
  }

  // Method to refresh cart count (can be called from parent widgets)
  void refreshCartCount() {
    _loadCartCount();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: widget.onTap,
          icon: Icon(
            Icons.shopping_cart,
            color: widget.iconColor ?? TColors.primary,
          ),
        ),
        if (_cartItemCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Text(
                _cartItemCount > 99 ? '99+' : _cartItemCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
