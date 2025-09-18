import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/services/firebase_service.dart';
import 'package:utmmart/features/auction/data/services/auction_firestore_service.dart';
import 'package:utmmart/features/auction/data/models/auction_model.dart';
import 'package:utmmart/features/auction/presentation/views/auction_detail_view.dart';
import 'package:utmmart/features/auction/presentation/views/create_auction_view.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';

class SellerDashboardView extends StatefulWidget {
  const SellerDashboardView({super.key});

  @override
  State<SellerDashboardView> createState() => _SellerDashboardViewState();
}

enum SellerOrderCategory { all, buy, auction }

enum SellerOrderStatusFilter {
  all,
  pending,
  approved,
  shipped,
  received,
  closed,
}

class _SellerDashboardViewState extends State<SellerDashboardView>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = sl<FirebaseService>();
  final AuctionFirestoreService _auctionService = sl<AuctionFirestoreService>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;
  String? _currentUserUid;
  Timer? _timer;

  // Filter states for Track Order tab
  SellerOrderCategory _selectedOrderCategory = SellerOrderCategory.all;
  SellerOrderStatusFilter _selectedOrderStatus = SellerOrderStatusFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getCurrentUser();
    _startTimer();
  }

  Future<void> _getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserUid = user.uid;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          // This will trigger a rebuild to update time remaining
        });
        // Check for expired auctions
        _checkExpiredAuctions();
      }
    });
  }

  Future<void> _checkExpiredAuctions() async {
    try {
      await _auctionService.checkAndEndExpiredAuctions();
    } catch (e) {
      print('Error checking expired auctions: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // Helper method to get price from various possible field names
  String _getPrice(Map<String, dynamic> data) {
    return (data['itemPrice'] ?? data['price'] ?? data['cost'] ?? 0.0)
        .toString();
  }

  // Helper method to get stock from various possible field names
  String _getStock(Map<String, dynamic> data) {
    return (data['itemStock'] ?? data['stock'] ?? data['quantity'] ?? 0)
        .toString();
  }

  // Helper method to get image URL from various possible field names
  String? _getImageUrl(Map<String, dynamic> data) {
    return data['itemImageUrl'] ??
        data['imageUrl'] ??
        data['image'] ??
        data['photo'] ??
        data['picture'] ??
        data['itemImage'];
  }

  // Edit item functionality
  void _editItem(
    BuildContext context,
    String itemId,
    Map<String, dynamic> data,
  ) {
    final nameController = TextEditingController(
      text: data['itemName'] ?? data['name'] ?? '',
    );
    final priceController = TextEditingController(text: _getPrice(data));
    final stockController = TextEditingController(text: _getStock(data));
    final descriptionController = TextEditingController(
      text: data['itemDescription'] ?? data['description'] ?? '',
    );
    final imageUrlController = TextEditingController(
      text: data['itemImageUrl'] ?? data['imageUrl'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  border: OutlineInputBorder(),
                  hintText: 'https://example.com/image.jpg',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateItem(itemId, {
                'itemName': nameController.text.trim(),
                'itemPrice': double.tryParse(priceController.text) ?? 0.0,
                'itemStock': int.tryParse(stockController.text) ?? 0,
                'itemDescription': descriptionController.text.trim(),
                'itemImageUrl': imageUrlController.text.trim(),
                'updatedAt': DateTime.now().toIso8601String(),
              });
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // Delete item functionality
  void _deleteItem(
    BuildContext context,
    String itemId,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text(
          'Are you sure you want to delete "${data['itemName'] ?? data['name'] ?? 'this item'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _deleteItemFromFirestore(itemId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Update item in Firestore
  Future<void> _updateItem(
    String itemId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      await _firebaseService.firestore
          .collection('store')
          .doc(itemId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Delete item from Firestore
  Future<void> _deleteItemFromFirestore(String itemId) async {
    try {
      await _firebaseService.firestore.collection('store').doc(itemId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Build pending order card
  Widget _buildPendingOrderCard(
    BuildContext context,
    String orderId,
    Map<String, dynamic> data,
  ) {
    final String status = data['status'] ?? 'pending';
    final bool isAuctionOrder = data['isAuctionOrder'] == true;
    final String customerName = data['customerName'] ?? 'Unknown Customer';
    final String customerEmail = data['customerEmail'] ?? 'No email';
    final String customerPhone = data['customerPhone'] ?? 'No phone';
    final double total = (data['total'] ?? 0.0).toDouble();
    final double subtotal = (data['subtotal'] ?? 0.0).toDouble();
    final double tax = (data['tax'] ?? 0.0).toDouble();
    final List<dynamic> items = data['items'] as List? ?? [];
    final Timestamp createdAt = data['createdAt'] as Timestamp;
    final DateTime orderDate = createdAt.toDate();
    final String formattedDate = DateFormat('dd MMM, yyyy').format(orderDate);
    final String formattedTime = DateFormat('HH:mm').format(orderDate);

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
                                ?.apply(fontWeightDelta: 2, color: Colors.blue),
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
                                      ? Icons.gavel
                                      : Icons.shopping_cart,
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
                        ).textTheme.bodySmall?.apply(color: Colors.grey[600]),
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
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TSizes.md),
                    border: Border.all(
                      color: _getStatusColor(status),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.apply(
                      color: _getStatusColor(status),
                      fontWeightDelta: 2,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: TSizes.lg),

            // Customer Details Section
            Container(
              padding: const EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(TSizes.md),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue, size: 20),
                      const SizedBox(width: TSizes.sm),
                      Text(
                        'Customer Details',
                        style: Theme.of(context).textTheme.titleMedium?.apply(
                          fontWeightDelta: 1,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.sm),
                  _buildDetailRow('Name', customerName, Icons.person_outline),
                  _buildDetailRow('Email', customerEmail, Icons.email_outlined),
                  _buildDetailRow('Phone', customerPhone, Icons.phone_outlined),
                ],
              ),
            ),

            const SizedBox(height: TSizes.lg),

            // Order Items Section
            Container(
              padding: const EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(TSizes.md),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_bag, color: Colors.green, size: 20),
                      const SizedBox(width: TSizes.sm),
                      Text(
                        'Order Items (${items.length})',
                        style: Theme.of(context).textTheme.titleMedium?.apply(
                          fontWeightDelta: 1,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.sm),
                  ...items.map((item) => _buildOrderItemRow(item)).toList(),
                ],
              ),
            ),

            const SizedBox(height: TSizes.lg),

            // Order Summary Section
            Container(
              padding: const EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(TSizes.md),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt, color: Colors.orange, size: 20),
                      const SizedBox(width: TSizes.sm),
                      Text(
                        'Order Summary',
                        style: Theme.of(context).textTheme.titleMedium?.apply(
                          fontWeightDelta: 1,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.sm),
                  _buildSummaryRow(
                    'Subtotal',
                    '\$${subtotal.toStringAsFixed(2)}',
                  ),
                  _buildSummaryRow('Tax', '\$${tax.toStringAsFixed(2)}'),
                  const Divider(),
                  _buildSummaryRow(
                    'Total',
                    '\$${total.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: TSizes.lg),

            // Action Buttons
            _buildStatusUpdateButtons(context, orderId, status),
          ],
        ),
      ),
    );
  }

  // Build detail row for customer info
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: TSizes.sm),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // Build order item row
  Widget _buildOrderItemRow(Map<String, dynamic> item) {
    final String itemName = item['itemName'] ?? 'Unknown Item';
    final int quantity = item['quantity'] ?? 0;
    final double price = (item['itemPrice'] ?? 0.0).toDouble();
    final double totalPrice = (item['totalPrice'] ?? 0.0).toDouble();
    final String itemImage = item['itemImageUrl'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      padding: const EdgeInsets.all(TSizes.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TSizes.sm),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
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
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(TSizes.sm),
              ),
              child: const Icon(Icons.image, color: Colors.grey),
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
                  'Qty: $quantity × \$${price.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),

          // Total Price
          Text(
            '\$${totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  // Build summary row
  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
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
              color: isTotal ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // Build status update buttons
  Widget _buildStatusUpdateButtons(
    BuildContext context,
    String orderId,
    String currentStatus,
  ) {
    return Row(
      children: [
        if (currentStatus == 'pending') ...[
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
        ],
        if (currentStatus == 'approved') ...[
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
        ],
        if (currentStatus == 'shipped') ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.md,
                vertical: TSizes.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(TSizes.sm),
                border: Border.all(color: Colors.orange),
              ),
              child: const Text(
                'PENDING RECEIVE CONFIRMATION',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
        if (currentStatus == 'received') ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showPaymentConfirmationDialog(orderId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Payment & Close'),
            ),
          ),
        ],
      ],
    );
  }

  // Show payment confirmation dialog
  void _showPaymentConfirmationDialog(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: const Text(
          'Have you received the cash payment from the customer? This will mark the order as completed and update the payment status to paid.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmPaymentAndCloseOrder(orderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }

  // Confirm payment and close order
  Future<void> _confirmPaymentAndCloseOrder(String orderId) async {
    try {
      print('🔄 Confirming payment and closing order $orderId');

      await _firebaseService.firestore
          .collection('orders')
          .doc(orderId)
          .update({
            'status': 'closed',
            'paymentStatus': 'paid',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print('✅ Order closed and payment confirmed successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order completed and payment confirmed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error confirming payment and closing order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Update order status
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      print('🔄 Updating order $orderId to status: $newStatus');

      await _firebaseService.firestore.collection('orders').doc(orderId).update(
        {'status': newStatus, 'updatedAt': FieldValue.serverTimestamp()},
      );

      print('✅ Order status updated successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating order status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'received':
        return Colors.green;
      case 'closed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Build auction items tab
  Widget _buildAuctionItemsTab() {
    if (_currentUserUid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Sub-tab bar for Active and Closed auctions
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: 'Active Auctions'),
                Tab(text: 'Closed Auctions'),
              ],
            ),
          ),

          // Sub-tab views
          Expanded(
            child: TabBarView(
              children: [_buildActiveAuctionsTab(), _buildClosedAuctionsTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAuctionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _auctionService.getUserActiveAuctionsStream(_currentUserUid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text(
                  'Error loading auctions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: TSizes.spaceBtwItems / 2),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gavel, size: 64, color: Colors.grey),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text(
                  'No active auctions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: TSizes.spaceBtwItems / 2),
                Text(
                  'Create your first auction to get started!',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: TSizes.lg),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        THelperFunctions.navigateToScreen(
                          context,
                          const CreateAuctionView(),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Start an Auction'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: TSizes.md,
                          horizontal: TSizes.lg,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final auctions = snapshot.data!.docs
            .map((doc) => AuctionModel.fromFirestore(doc))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          itemCount: auctions.length,
          itemBuilder: (context, index) {
            final auction = auctions[index];
            return _buildAuctionCard(auction, isActive: true);
          },
        );
      },
    );
  }

  Widget _buildClosedAuctionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _auctionService.getUserClosedAuctionsStream(_currentUserUid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text(
                  'Error loading auctions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: TSizes.spaceBtwItems / 2),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 64, color: Colors.grey),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text(
                  'No closed auctions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: TSizes.spaceBtwItems / 2),
                Text(
                  'Your completed auctions will appear here.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final auctions = snapshot.data!.docs
            .map((doc) => AuctionModel.fromFirestore(doc))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          itemCount: auctions.length,
          itemBuilder: (context, index) {
            final auction = auctions[index];
            return _buildAuctionCard(auction, isActive: false);
          },
        );
      },
    );
  }

  Widget _buildAuctionCard(AuctionModel auction, {required bool isActive}) {
    final highestBid = auction.highestBid;

    return Card(
      margin: const EdgeInsets.only(bottom: TSizes.md),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          THelperFunctions.navigateToScreen(
            context,
            AuctionDetailView(auction: auction),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(TSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Auction Image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        auction.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.withOpacity(0.1),
                            child: const Icon(Icons.image_not_supported),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: TSizes.sm),

                  // Auction Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auction.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auction.category,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              isActive ? Icons.access_time : Icons.check_circle,
                              size: 14,
                              color: isActive ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isActive ? 'Active' : 'Ended',
                              style: TextStyle(
                                color: isActive ? Colors.green : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Current Bid
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${auction.currentBid.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Current Bid',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: TSizes.sm),

              // Bidding Info
              if (highestBid != null) ...[
                Container(
                  padding: const EdgeInsets.all(TSizes.sm),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? Colors.blue : Colors.green,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isActive ? Icons.person : Icons.emoji_events,
                        size: 16,
                        color: isActive ? Colors.blue : Colors.green,
                      ),
                      const SizedBox(width: TSizes.xs),
                      Text(
                        isActive
                            ? 'Highest bidder: ${highestBid.bidderName}'
                            : 'Winner: ${highestBid.bidderName}',
                        style: TextStyle(
                          color: isActive
                              ? Colors.blue[700]
                              : Colors.green[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TSizes.sm),
              ],

              // Time Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Started: ${_formatDate(auction.startTime)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  Text(
                    isActive
                        ? 'Ends: ${_formatTimeRemaining(auction.endTime)}'
                        : 'Ended: ${_formatDate(auction.endTime)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isActive ? Colors.orange[600] : Colors.red[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  String _formatTimeRemaining(DateTime endTime) {
    final now = DateTime.now();
    if (now.isAfter(endTime)) {
      return 'Ended';
    }

    final difference = endTime.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} left';
    } else {
      return 'Ending soon';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          title: Text(
            "Seller Dashboard",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "My Store"),
              Tab(text: "Track Order"),
              Tab(text: "Auction Items"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // To Sell Tab - Store items where current user is seller
                Padding(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firebaseService.firestore
                        .collection('store')
                        .where(
                          'sellerUid',
                          isEqualTo: _firebaseService.currentUser?.uid,
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.store_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: TSizes.spaceBtwItems),
                              Text(
                                'No items to sell',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: TSizes.spaceBtwItems / 2),
                              Text(
                                'Add items to your store to start selling',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      // Filter out items with 0 stock
                      final itemsWithStock = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final stock =
                            data['itemStock'] ??
                            data['stock'] ??
                            data['quantity'] ??
                            0;
                        return stock > 0;
                      }).toList();

                      if (itemsWithStock.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: TSizes.spaceBtwItems),
                              Text(
                                'No items in stock',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: TSizes.spaceBtwItems / 2),
                              Text(
                                'All your items are out of stock',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: itemsWithStock.length,
                        itemBuilder: (context, index) {
                          final doc = itemsWithStock[index];
                          final data = doc.data() as Map<String, dynamic>;

                          // Debug: Print the document data to see what fields are available
                          print('Store item data: $data');
                          print(
                            'Description field: ${data['itemDescription'] ?? data['description'] ?? 'NOT FOUND'}',
                          );
                          print(
                            'Image field: ${data['itemImageUrl'] ?? data['imageUrl'] ?? data['image'] ?? 'NOT FOUND'}',
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: TSizes.sm),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: _getImageUrl(data) != null
                                    ? NetworkImage(_getImageUrl(data)!)
                                    : null,
                                child: _getImageUrl(data) == null
                                    ? const Icon(Icons.image)
                                    : null,
                              ),
                              title: Text(
                                data['itemName'] ??
                                    data['name'] ??
                                    data['title'] ??
                                    'Unknown Item',
                              ),
                              subtitle: Text(
                                'Price: \$${_getPrice(data)}\n'
                                'Stock: ${_getStock(data)}',
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _editItem(context, doc.id, data);
                                  } else if (value == 'delete') {
                                    _deleteItem(context, doc.id, data);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                // Track Order Tab
                Column(
                  children: [
                    // Filter Header - Compact Design
                    Container(
                      margin: const EdgeInsets.all(TSizes.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: TSizes.md,
                        vertical: TSizes.sm,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(TSizes.md),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            spreadRadius: 0,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Order Type Filter - Compact
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildSellerFilterChip(
                                    'All',
                                    _selectedOrderCategory ==
                                        SellerOrderCategory.all,
                                    Iconsax.bag,
                                    () => setState(
                                      () => _selectedOrderCategory =
                                          SellerOrderCategory.all,
                                    ),
                                  ),
                                  const SizedBox(width: TSizes.xs),
                                  _buildSellerFilterChip(
                                    'Sales',
                                    _selectedOrderCategory ==
                                        SellerOrderCategory.buy,
                                    Iconsax.shopping_cart,
                                    () => setState(
                                      () => _selectedOrderCategory =
                                          SellerOrderCategory.buy,
                                    ),
                                  ),
                                  const SizedBox(width: TSizes.xs),
                                  _buildSellerFilterChip(
                                    'Auctions',
                                    _selectedOrderCategory ==
                                        SellerOrderCategory.auction,
                                    Iconsax.crown,
                                    () => setState(
                                      () => _selectedOrderCategory =
                                          SellerOrderCategory.auction,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Status Filter Button - Compact
                          Container(
                            margin: const EdgeInsets.only(left: TSizes.xs),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _showSellerFilterBottomSheet,
                                borderRadius: BorderRadius.circular(TSizes.sm),
                                child: Container(
                                  padding: const EdgeInsets.all(TSizes.xs),
                                  child: Stack(
                                    children: [
                                      Icon(
                                        Iconsax.filter,
                                        size: 20,
                                        color:
                                            _selectedOrderStatus !=
                                                SellerOrderStatusFilter.all
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey[600],
                                      ),
                                      if (_selectedOrderStatus !=
                                          SellerOrderStatusFilter.all)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).primaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Orders List
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(TSizes.defaultSpace),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _firebaseService.firestore
                              .collection('orders')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return _buildSellerEmptyState();
                            }

                            // Filter orders for seller
                            final filteredOrders = _filterSellerOrders(
                              snapshot.data!.docs,
                            );

                            if (filteredOrders.isEmpty) {
                              return _buildSellerEmptyState(isFiltered: true);
                            }

                            return ListView.builder(
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) {
                                final doc = filteredOrders[index];
                                final data = doc.data() as Map<String, dynamic>;
                                return _buildPendingOrderCard(
                                  context,
                                  doc.id,
                                  data,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                // Auction Items Tab
                _buildAuctionItemsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Seller dashboard filter methods
  Widget _buildSellerFilterChip(
    String label,
    bool isSelected,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TSizes.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TSizes.sm,
            vertical: TSizes.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(TSizes.lg),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.withOpacity(0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
              ),
              const SizedBox(width: TSizes.xs / 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSellerFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(TSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter by Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_selectedOrderStatus != SellerOrderStatusFilter.all)
                  TextButton(
                    onPressed: () {
                      setState(
                        () =>
                            _selectedOrderStatus = SellerOrderStatusFilter.all,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: TSizes.lg),
            Wrap(
              spacing: TSizes.sm,
              runSpacing: TSizes.sm,
              children: [
                _buildSellerStatusChip(
                  'All',
                  SellerOrderStatusFilter.all,
                  Iconsax.menu,
                ),
                _buildSellerStatusChip(
                  'Pending',
                  SellerOrderStatusFilter.pending,
                  Iconsax.clock,
                ),
                _buildSellerStatusChip(
                  'Approved',
                  SellerOrderStatusFilter.approved,
                  Iconsax.tick_circle,
                ),
                _buildSellerStatusChip(
                  'Shipped',
                  SellerOrderStatusFilter.shipped,
                  Iconsax.ship,
                ),
                _buildSellerStatusChip(
                  'Received',
                  SellerOrderStatusFilter.received,
                  Iconsax.box,
                ),
                _buildSellerStatusChip(
                  'Completed',
                  SellerOrderStatusFilter.closed,
                  Iconsax.verify,
                ),
              ],
            ),
            const SizedBox(height: TSizes.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerStatusChip(
    String label,
    SellerOrderStatusFilter status,
    IconData icon,
  ) {
    final isSelected = _selectedOrderStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedOrderStatus = status);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TSizes.md,
          vertical: TSizes.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(TSizes.lg),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: TSizes.xs),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<QueryDocumentSnapshot> _filterSellerOrders(
    List<QueryDocumentSnapshot> orders,
  ) {
    final currentUserId = _firebaseService.currentUser?.uid;

    var filteredOrders = orders.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'pending';
      final isAuctionOrder = data['isAuctionOrder'] == true;

      // Check if current user is the seller in any of the items
      final items = data['items'] as List<dynamic>? ?? [];
      final isSellerOrder = items.any((item) {
        final itemData = item as Map<String, dynamic>;
        return itemData['sellerUid'] == currentUserId;
      });

      if (!isSellerOrder) return false;

      // Filter by order category (buy/auction)
      if (_selectedOrderCategory != SellerOrderCategory.all) {
        if (_selectedOrderCategory == SellerOrderCategory.auction &&
            !isAuctionOrder) {
          return false;
        }
        if (_selectedOrderCategory == SellerOrderCategory.buy &&
            isAuctionOrder) {
          return false;
        }
      }

      // Filter by status
      if (_selectedOrderStatus != SellerOrderStatusFilter.all) {
        final statusMatch = _selectedOrderStatus.toString().split('.').last;
        if (status != statusMatch) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort orders by creation date (newest first), with pending orders prioritized
    filteredOrders.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aStatus = aData['status'] ?? 'pending';
      final bStatus = bData['status'] ?? 'pending';
      final aCreatedAt = aData['createdAt'] as Timestamp;
      final bCreatedAt = bData['createdAt'] as Timestamp;

      // Prioritize pending orders first
      if (aStatus == 'pending' && bStatus != 'pending') return -1;
      if (bStatus == 'pending' && aStatus != 'pending') return 1;

      // Then sort by date (newest first)
      return bCreatedAt.compareTo(aCreatedAt);
    });

    return filteredOrders;
  }

  Widget _buildSellerEmptyState({bool isFiltered = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Iconsax.filter_search : Icons.shopping_bag_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text(
            isFiltered ? 'No orders match your filters' : 'No orders found',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: TSizes.spaceBtwItems / 2),
          Text(
            isFiltered
                ? 'Try adjusting your filter criteria'
                : 'Orders will appear here when customers place them',
            style: const TextStyle(color: Colors.grey),
          ),
          if (isFiltered) ...[
            const SizedBox(height: TSizes.spaceBtwItems),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedOrderCategory = SellerOrderCategory.all;
                  _selectedOrderStatus = SellerOrderStatusFilter.all;
                });
              },
              icon: const Icon(Iconsax.refresh, size: 16),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
