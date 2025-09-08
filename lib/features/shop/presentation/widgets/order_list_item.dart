import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmmart/core/common/view_models/circular_container_view_model.dart';
import 'package:utmmart/core/common/widgets/circular_container.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:intl/intl.dart';

class OrderListItem extends StatelessWidget {
  final QueryDocumentSnapshot order;

  const OrderListItem({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final data = order.data() as Map<String, dynamic>;

    // Extract order data
    final String orderId = order.id;
    final String status = data['status'] ?? 'pending';
    final String paymentStatus = data['paymentStatus'] ?? 'pending';
    final double total = (data['total'] ?? 0.0).toDouble();
    final int itemCount = (data['items'] as List?)?.length ?? 0;
    final Timestamp createdAt = data['createdAt'] as Timestamp;
    final DateTime orderDate = createdAt.toDate();

    // Format date
    final String formattedDate = DateFormat('dd MMM, yyyy').format(orderDate);

    // Get status color and icon
    final statusInfo = _getStatusInfo(status);

    return CircularContainer(
      circularContainerModel: CircularContainerModel(
        showBorder: true,
        color: dark ? TColors.dark : TColors.light,
        padding: const EdgeInsets.all(TSizes.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(statusInfo['icon'], color: statusInfo['color']),
                const SizedBox(width: TSizes.spaceBtwItems / 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        statusInfo['text'],
                        style: Theme.of(context).textTheme.bodyLarge!.apply(
                          color: statusInfo['color'],
                          fontWeightDelta: 1,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Iconsax.tag),
                      const SizedBox(width: TSizes.spaceBtwItems / 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Order",
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            Text(
                              "#${orderId.substring(0, 8)}",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Iconsax.shopping_bag),
                      const SizedBox(width: TSizes.spaceBtwItems / 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Items",
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            Text(
                              "$itemCount item${itemCount != 1 ? 's' : ''}",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: TSizes.spaceBtwItems / 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total: \$${total.toStringAsFixed(2)}",
                  style: Theme.of(context).textTheme.titleMedium?.apply(
                    fontWeightDelta: 1,
                    color: TColors.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TSizes.sm,
                    vertical: TSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _getPaymentStatusColor(
                      paymentStatus,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TSizes.sm),
                    border: Border.all(
                      color: _getPaymentStatusColor(paymentStatus),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    paymentStatus.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.apply(
                      color: _getPaymentStatusColor(paymentStatus),
                      fontWeightDelta: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {
          'text': 'Processing',
          'icon': Iconsax.clock,
          'color': Colors.orange,
        };
      case 'confirmed':
        return {
          'text': 'Confirmed',
          'icon': Iconsax.tick_circle,
          'color': Colors.blue,
        };
      case 'processing':
        return {
          'text': 'Processing',
          'icon': Iconsax.settings,
          'color': Colors.blue,
        };
      case 'shipped':
        return {
          'text': 'Shipped',
          'icon': Iconsax.ship,
          'color': Colors.purple,
        };
      case 'delivered':
        return {
          'text': 'Delivered',
          'icon': Iconsax.tick_circle,
          'color': Colors.green,
        };
      case 'cancelled':
        return {
          'text': 'Cancelled',
          'icon': Iconsax.close_circle,
          'color': Colors.red,
        };
      case 'returned':
        return {
          'text': 'Returned',
          'icon': Iconsax.arrow_left,
          'color': Colors.orange,
        };
      case 'refunded':
        return {
          'text': 'Refunded',
          'icon': Iconsax.money_send,
          'color': Colors.grey,
        };
      default:
        return {
          'text': 'Unknown',
          'icon': Iconsax.info_circle,
          'color': Colors.grey,
        };
    }
  }

  Color _getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      case 'partiallyrefunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
