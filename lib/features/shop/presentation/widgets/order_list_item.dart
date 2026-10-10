import 'package:flutter/material.dart';
import 'package:utmmart/features/notifications/data/models/notification_model.dart';
import 'package:utmmart/features/notifications/data/services/notification_service.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/features/shop/data/services/order_service.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/services/firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderListItem extends StatefulWidget {
  final DocumentSnapshot order;

  const OrderListItem({super.key, required this.order});

  @override
  State<OrderListItem> createState() => _OrderListItemState();
}

class _OrderListItemState extends State<OrderListItem> {
  final FirebaseService _firebaseService = sl<FirebaseService>();
  final NotificationService _notificationService = NotificationService();
  Map<String, String?>? _vendorInfo;
  Map<String, String?>? _customerInfo;

  @override
  void initState() {
    super.initState();
    _loadContactInfo();
  }

  Future<void> _loadContactInfo() async {
    final data = widget.order.data() as Map<String, dynamic>;

    // Load seller info if missing
    String? sellerUid;
    if (data['sellerUid'] != null) {
      // For auction orders - sellerUid is at order level
      sellerUid = data['sellerUid'];
    } else if (data['items'] != null && (data['items'] as List).isNotEmpty) {
      // For regular orders - sellerUid is in the first item
      final firstItem = (data['items'] as List).first as Map<String, dynamic>;
      sellerUid = firstItem['sellerUid'];
    }

    if (data['vendorPhone'] == null && sellerUid != null) {
      debugPrint('🔍 Loading seller info for ID: $sellerUid');
      final sellerInfo = await _getUserInfo(sellerUid);
      debugPrint('📞 Seller info loaded: $sellerInfo');
      if (mounted) {
        setState(() {
          _vendorInfo = sellerInfo;
        });
      }
    }

    // Load customer info if missing (for auction orders)
    if (data['customerPhone'] == null &&
        data['customerId'] != null &&
        data['isAuctionOrder'] == true) {
      debugPrint('🔍 Loading customer info for ID: ${data['customerId']}');
      final customerInfo = await _getUserInfo(data['customerId']);
      debugPrint('📞 Customer info loaded: $customerInfo');
      if (mounted) {
        setState(() {
          _customerInfo = customerInfo;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.order.data() as Map<String, dynamic>;

    // Extract order data
    final String orderId = widget.order.id;
    final String status = data['status'] ?? 'pending';
    final String paymentStatus = data['paymentStatus'] ?? 'pending';
    final bool isAuctionOrder = data['isAuctionOrder'] == true;
    final double total = (data['total'] ?? 0.0).toDouble();
    final double subtotal = (data['subtotal'] ?? 0.0).toDouble();
    final double tax = (data['tax'] ?? 0.0).toDouble();
    final List<dynamic> items = data['items'] as List? ?? [];
    final Timestamp createdAt = data['createdAt'] as Timestamp;
    final DateTime orderDate = createdAt.toDate();

    // Format date and time
    final String formattedDate = DateFormat('dd MMM, yyyy').format(orderDate);
    final String formattedTime = DateFormat('HH:mm').format(orderDate);

    final dark = THelperFunctions.isDarkMode(context);
    final muted = THelperFunctions.mutedTextColor(context);
    // Section accents: brighter shades on dark surfaces for contrast.
    final blue = dark ? Colors.blue.shade200 : Colors.blue;
    final green = dark ? Colors.green.shade300 : Colors.green;
    final orange = dark ? Colors.orange.shade300 : Colors.orange;

    // Get status color and icon
    final statusInfo = _getStatusInfo(status);

    return Card(
      margin: const EdgeInsets.only(bottom: TSizes.md),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(TSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${orderId.substring(0, 12)}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.apply(fontWeightDelta: 2, color: blue),
                          ),
                          const SizedBox(height: TSizes.xs / 2),
                          // Order Type Badge - Compact
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: TSizes.xs,
                              vertical: TSizes.xs / 4,
                            ),
                            decoration: BoxDecoration(
                              color: isAuctionOrder
                                  ? Colors.purple.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(TSizes.xs),
                              border: Border.all(
                                color: isAuctionOrder
                                    ? Colors.purple
                                    : Colors.green,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAuctionOrder
                                      ? Iconsax.crown
                                      : Iconsax.shopping_cart,
                                  size: 10,
                                  color: isAuctionOrder
                                      ? Colors.purple
                                      : Colors.green,
                                ),
                                const SizedBox(width: TSizes.xs / 4),
                                Text(
                                  isAuctionOrder ? 'AUCTION' : 'BUY',
                                  style: TextStyle(
                                    color: isAuctionOrder
                                        ? Colors.purple
                                        : Colors.green,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TSizes.xs / 2),
                      Text(
                        '$formattedDate at $formattedTime',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.apply(color: muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TSizes.md,
                    vertical: TSizes.sm,
                  ),
                  decoration: BoxDecoration(
                    color: statusInfo['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TSizes.md),
                    border: Border.all(color: statusInfo['color'], width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusInfo['icon'],
                        color: statusInfo['color'],
                        size: 16,
                      ),
                      const SizedBox(width: TSizes.xs),
                      Text(
                        statusInfo['text'].toUpperCase(),
                        style: Theme.of(context).textTheme.labelMedium?.apply(
                          color: statusInfo['color'],
                          fontWeightDelta: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: TSizes.lg),

            // Order Items Section
            Container(
              padding: const EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                color: blue.withOpacity(dark ? 0.12 : 0.05),
                borderRadius: BorderRadius.circular(TSizes.md),
                border: Border.all(color: blue.withOpacity(dark ? 0.35 : 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_bag, color: blue, size: 20),
                      const SizedBox(width: TSizes.sm),
                      Text(
                        'Order Items (${items.length})',
                        style: Theme.of(context).textTheme.titleMedium?.apply(
                          fontWeightDelta: 1,
                          color: blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.sm),
                  ...items.map((item) => _buildOrderItemRow(item)),
                ],
              ),
            ),

            const SizedBox(height: TSizes.lg),

            // Order Summary Section
            Container(
              padding: const EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                color: green.withOpacity(dark ? 0.12 : 0.05),
                borderRadius: BorderRadius.circular(TSizes.md),
                border: Border.all(color: green.withOpacity(dark ? 0.35 : 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt, color: green, size: 20),
                      const SizedBox(width: TSizes.sm),
                      Text(
                        'Order Summary',
                        style: Theme.of(context).textTheme.titleMedium?.apply(
                          fontWeightDelta: 1,
                          color: green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.sm),
                  _buildSummaryRow(
                    'Subtotal',
                    'RM${subtotal.toStringAsFixed(2)}',
                  ),
                  _buildSummaryRow('Tax', 'RM${tax.toStringAsFixed(2)}'),
                  const Divider(),
                  _buildSummaryRow(
                    'Total',
                    'RM${total.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: TSizes.lg),

            // Contact Information Section
            Container(
              padding: const EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                color: orange.withOpacity(dark ? 0.12 : 0.05),
                borderRadius: BorderRadius.circular(TSizes.md),
                border: Border.all(color: orange.withOpacity(dark ? 0.35 : 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.contact_phone, color: orange, size: 20),
                      const SizedBox(width: TSizes.sm),
                      Text(
                        'Contact Information',
                        style: Theme.of(context).textTheme.titleMedium?.apply(
                          fontWeightDelta: 1,
                          color: orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.sm),
                  Row(
                    children: [
                      // Buyer Contact
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Buyer',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.apply(
                                    fontWeightDelta: 2,
                                    color: orange,
                                  ),
                            ),
                            const SizedBox(height: TSizes.xs / 2),
                            Text(
                              data['customerName'] ??
                                  _customerInfo?['name'] ??
                                  'N/A',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.apply(fontWeightDelta: 1),
                            ),
                            GestureDetector(
                              onTap: () => _makePhoneCall(
                                data['customerPhone'] ??
                                    _customerInfo?['phone'],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.phone,
                                    size: 14,
                                    color: orange,
                                  ),
                                  const SizedBox(width: TSizes.xs / 2),
                                  Text(
                                    data['customerPhone'] ??
                                        _customerInfo?['phone'] ??
                                        'N/A',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.apply(
                                          color:
                                              (data['customerPhone'] ??
                                                      _customerInfo?['phone']) !=
                                                  null
                                              ? orange
                                              : muted,
                                          decoration:
                                              (data['customerPhone'] ??
                                                      _customerInfo?['phone']) !=
                                                  null
                                              ? TextDecoration.underline
                                              : TextDecoration.none,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Seller Contact
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seller',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.apply(
                                    fontWeightDelta: 2,
                                    color: orange,
                                  ),
                            ),
                            const SizedBox(height: TSizes.xs / 2),
                            Text(
                              data['vendorName'] ??
                                  data['sellerName'] ??
                                  _vendorInfo?['name'] ??
                                  'N/A',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.apply(fontWeightDelta: 1),
                            ),
                            GestureDetector(
                              onTap: () => _makePhoneCall(
                                data['vendorPhone'] ?? _vendorInfo?['phone'],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.phone,
                                    size: 14,
                                    color: orange,
                                  ),
                                  const SizedBox(width: TSizes.xs / 2),
                                  Text(
                                    data['vendorPhone'] ??
                                        _vendorInfo?['phone'] ??
                                        'N/A',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.apply(
                                          color:
                                              (data['vendorPhone'] ??
                                                      _vendorInfo?['phone']) !=
                                                  null
                                              ? orange
                                              : muted,
                                          decoration:
                                              (data['vendorPhone'] ??
                                                      _vendorInfo?['phone']) !=
                                                  null
                                              ? TextDecoration.underline
                                              : TextDecoration.none,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: TSizes.lg),

            // Payment Status and Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TSizes.md,
                      vertical: TSizes.sm,
                    ),
                    decoration: BoxDecoration(
                      color: _getPaymentStatusColor(
                        paymentStatus,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(TSizes.md),
                      border: Border.all(
                        color: _getPaymentStatusColor(paymentStatus),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Payment: ${paymentStatus.toUpperCase()}',
                      style: Theme.of(context).textTheme.labelMedium?.apply(
                        color: _getPaymentStatusColor(paymentStatus),
                        fontWeightDelta: 1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                const SizedBox(width: TSizes.sm),

                // Add confirmation button for shipped orders
                if (status == 'shipped')
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showReceiveConfirmation(context, orderId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: TSizes.sm,
                          vertical: TSizes.sm,
                        ),
                      ),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text(
                        'Received',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                if (status == 'shipped') ...[
                  const SizedBox(width: TSizes.xs),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () => _showReturnConfirmation(context, orderId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                          horizontal: TSizes.sm,
                          vertical: TSizes.sm,
                        ),
                      ),
                      icon: const Icon(Icons.undo, size: 16),
                      label: const Text(
                        'Return',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build order item row
  Widget _buildOrderItemRow(Map<String, dynamic> item) {
    final dark = THelperFunctions.isDarkMode(context);
    final muted = THelperFunctions.mutedTextColor(context);
    final String itemName = item['itemName'] ?? 'Unknown Item';
    final int quantity = item['quantity'] ?? 0;
    final double price = (item['itemPrice'] ?? 0.0).toDouble();
    final double totalPrice = (item['totalPrice'] ?? 0.0).toDouble();
    final String itemImage = item['itemImageUrl'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      padding: const EdgeInsets.all(TSizes.sm),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.sm),
        border: Border.all(
          color: dark ? Colors.white24 : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Item Image
          if (itemImage.isNotEmpty)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TSizes.sm),
                image: DecorationImage(
                  image: NetworkImage(itemImage),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: dark ? Colors.white12 : Colors.grey[200],
                borderRadius: BorderRadius.circular(TSizes.sm),
              ),
              child: Icon(Icons.image, color: muted),
            ),

          const SizedBox(width: TSizes.sm),

          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty: $quantity × RM${price.toStringAsFixed(2)}',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),

          // Total Price
          Text(
            'RM${totalPrice.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: dark ? Colors.blue.shade200 : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  // Build summary row
  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    final dark = THelperFunctions.isDarkMode(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 18 : 14,
              color: isTotal
                  ? (dark ? Colors.blue.shade200 : Colors.blue)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // Buyer didn't like the shipped item: cancel and send it back
  void _showReturnConfirmation(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actionsOverflowButtonSpacing: 8,
        title: const Text('Cancel and return?'),
        content: const Text(
          'The order will be cancelled and you hand the item back to the seller.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep order'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await OrderService().cancelOrder(orderId, byBuyer: true);
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Order cancelled'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text('Could not cancel: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
  }

  // Show confirmation dialog for received orders
  void _showReceiveConfirmation(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actionsOverflowButtonSpacing: 8,
        title: const Text('Confirm Received'),
        content: const Text(
          'Have you received this order? The seller will then confirm your cash payment to complete it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmReceived(orderId);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // Confirm order as received. Stock is only reduced at checkout.
  Future<void> _confirmReceived(String orderId) async {
    try {
      debugPrint('🔍 Customer confirming order received: $orderId');

      await _firebaseService.firestore.collection('orders').doc(orderId).update(
        {'status': 'received', 'updatedAt': FieldValue.serverTimestamp()},
      );

      final orderData = widget.order.data() as Map<String, dynamic>;
      final sellerIds = <String>{
        if (orderData['sellerUid'] is String) orderData['sellerUid'] as String,
        ...((orderData['sellerUids'] as List?) ?? const []).whereType<String>(),
      };
      for (final sellerId in sellerIds) {
        await _notificationService.notifyUser(
          userId: sellerId,
          title: 'Order Received',
          message:
              'The customer confirmed order #${orderId.substring(0, 8)} as received',
          type: NotificationType.orderStatusChange,
          data: {'orderId': orderId, 'newStatus': 'received', 'sellerTab': 1, 'asSeller': true},
        );
      }

      debugPrint('✅ Order status updated to received');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order confirmed as received!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error confirming order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        return {'text': 'Received', 'icon': Iconsax.box, 'color': Colors.teal};
      case 'closed':
        return {
          'text': 'Completed',
          'icon': Iconsax.verify,
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

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot make phone call'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making phone call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, String?>> _getUserInfo(String userId) async {
    try {
      debugPrint('🔍 Fetching user info for ID: $userId');
      final userDoc = await _firebaseService.firestore
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        debugPrint('✅ User document found: $userData');
        final result = <String, String?>{
          'name': '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
              .trim(),
          'phone': userData['phoneNumber'] ?? '',
        };
        debugPrint('📞 Processed user info: $result');
        return result;
      } else {
        debugPrint('❌ User document not found for ID: $userId');
        return {'name': 'Unknown User', 'phone': ''};
      }
    } catch (e) {
      debugPrint('❌ Error getting user info for $userId: $e');
      return {'name': 'Unknown User', 'phone': ''};
    }
  }
}
