import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmmart/core/common/view_models/circular_container_view_model.dart';
import 'package:utmmart/core/common/widgets/circular_container.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:intl/intl.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/services/firebase_service.dart';

class SellerOrderItem extends StatefulWidget {
  final QueryDocumentSnapshot order;

  const SellerOrderItem({super.key, required this.order});

  @override
  State<SellerOrderItem> createState() => _SellerOrderItemState();
}

class _SellerOrderItemState extends State<SellerOrderItem> {
  final FirebaseService _firebaseService = sl<FirebaseService>();
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final data = widget.order.data() as Map<String, dynamic>;

    // Extract order data
    final String orderId = widget.order.id;
    final String status = data['status'] ?? 'pending';
    final double total = (data['total'] ?? 0.0).toDouble();
    final int itemCount = (data['items'] as List?)?.length ?? 0;
    final Timestamp createdAt = data['createdAt'] as Timestamp;
    final DateTime orderDate = createdAt.toDate();
    final String customerName = data['customerName'] ?? 'Unknown Customer';

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
            // Header with status and date
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

            // Order details
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
                      const Icon(Iconsax.user),
                      const SizedBox(width: TSizes.spaceBtwItems / 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Customer",
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            Text(
                              customerName,
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

            // Total amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total: RM${total.toStringAsFixed(2)}",
                  style: Theme.of(context).textTheme.titleMedium?.apply(
                    fontWeightDelta: 1,
                    color: TColors.primary,
                  ),
                ),
                Text(
                  "$itemCount item${itemCount != 1 ? 's' : ''}",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Action buttons based on status
            _buildActionButtons(status, orderId),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(String status, String orderId) {
    if (_isUpdating) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(TSizes.md),
          child: CircularProgressIndicator(),
        ),
      );
    }

    switch (status.toLowerCase()) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus(orderId, 'approved'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Approve'),
              ),
            ),
            const SizedBox(width: TSizes.sm),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateOrderStatus(orderId, 'cancelled'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        );
      case 'approved':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus(orderId, 'shipped'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Mark as Shipped'),
              ),
            ),
            const SizedBox(width: TSizes.sm),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateOrderStatus(orderId, 'cancelled'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        );
      case 'shipped':
        return Container(
          padding: const EdgeInsets.all(TSizes.sm),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(TSizes.sm),
            border: Border.all(color: Colors.purple),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.ship, color: Colors.purple, size: 16),
              const SizedBox(width: TSizes.xs),
              Text(
                'Waiting for customer confirmation',
                style: Theme.of(context).textTheme.bodySmall?.apply(
                  color: Colors.purple,
                  fontWeightDelta: 1,
                ),
              ),
            ],
          ),
        );
      case 'received':
        return Container(
          padding: const EdgeInsets.all(TSizes.sm),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(TSizes.sm),
            border: Border.all(color: Colors.green),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.tick_circle, color: Colors.green, size: 16),
              const SizedBox(width: TSizes.xs),
              Text(
                'Order completed',
                style: Theme.of(context).textTheme.bodySmall?.apply(
                  color: Colors.green,
                  fontWeightDelta: 1,
                ),
              ),
            ],
          ),
        );
      case 'cancelled':
        return Container(
          padding: const EdgeInsets.all(TSizes.sm),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(TSizes.sm),
            border: Border.all(color: Colors.red),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.close_circle, color: Colors.red, size: 16),
              const SizedBox(width: TSizes.xs),
              Text(
                'Order cancelled',
                style: Theme.of(context).textTheme.bodySmall?.apply(
                  color: Colors.red,
                  fontWeightDelta: 1,
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await _firebaseService.firestore.collection('orders').doc(orderId).update(
        {'status': newStatus, 'updatedAt': FieldValue.serverTimestamp()},
      );

      // If status is being changed to approved, update stock
      if (newStatus == 'approved') {
        await _updateStockForOrder(orderId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _updateStockForOrder(String orderId) async {
    try {
      final orderDoc = await _firebaseService.firestore
          .collection('orders')
          .doc(orderId)
          .get();

      if (orderDoc.exists) {
        final orderData = orderDoc.data() as Map<String, dynamic>;
        final items = orderData['items'] as List<dynamic>? ?? [];

        for (final item in items) {
          final itemData = item as Map<String, dynamic>;
          final itemId = itemData['itemId'] as String?;
          final quantity = itemData['quantity'] as int? ?? 0;

          if (itemId != null) {
            // Update stock in store collection
            final storeDoc = await _firebaseService.firestore
                .collection('store')
                .doc(itemId)
                .get();

            if (storeDoc.exists) {
              final currentStock = storeDoc.data()?['itemStock'] ?? 0;
              final newStock = currentStock - quantity;

              await _firebaseService.firestore
                  .collection('store')
                  .doc(itemId)
                  .update({'itemStock': newStock < 0 ? 0 : newStock});
            }
          }
        }
      }
    } catch (e) {
      print('Error updating stock: $e');
    }
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {
          'text': 'Pending',
          'icon': Iconsax.clock,
          'color': Colors.orange,
        };
      case 'approved':
        return {
          'text': 'Approved',
          'icon': Iconsax.tick_circle,
          'color': Colors.blue,
        };
      case 'shipped':
        return {
          'text': 'Shipped',
          'icon': Iconsax.ship,
          'color': Colors.purple,
        };
      case 'received':
        return {
          'text': 'Received',
          'icon': Iconsax.tick_circle,
          'color': Colors.green,
        };
      case 'cancelled':
        return {
          'text': 'Cancelled',
          'icon': Iconsax.close_circle,
          'color': Colors.red,
        };
      default:
        return {
          'text': 'Unknown',
          'icon': Iconsax.info_circle,
          'color': Colors.grey,
        };
    }
  }
}
