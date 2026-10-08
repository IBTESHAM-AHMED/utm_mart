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

  @override
  void initState() {
    super.initState();
    // Loads the signed-in user's count (also covers an account switch).
    _cartService.refreshItemCount();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _cartService.itemCount,
      builder: (context, cartItemCount, _) => Stack(
        children: [
          IconButton(
            onPressed: widget.onTap,
            icon: Icon(
              Icons.shopping_cart,
              color: widget.iconColor ?? TColors.primary,
            ),
          ),
          if (cartItemCount > 0)
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
                  cartItemCount > 99 ? '99+' : cartItemCount.toString(),
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
      ),
    );
  }
}
