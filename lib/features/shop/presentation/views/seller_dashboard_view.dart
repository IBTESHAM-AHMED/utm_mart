import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/services/firebase_service.dart';
import 'package:intl/intl.dart';

class SellerDashboardView extends StatefulWidget {
  const SellerDashboardView({super.key});

  @override
  State<SellerDashboardView> createState() => _SellerDashboardViewState();
}

class _SellerDashboardViewState extends State<SellerDashboardView>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = sl<FirebaseService>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
                      Text(
                        'Order #${orderId.substring(0, 12)}',
                        style: Theme.of(context).textTheme.titleLarge?.apply(
                          fontWeightDelta: 2,
                          color: Colors.blue,
                        ),
                      ),
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
            child: ElevatedButton(
              onPressed: () => _updateOrderStatus(orderId, 'closed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Close Order'),
            ),
          ),
          const SizedBox(width: TSizes.sm),
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
      ],
    );
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
                Padding(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firebaseService.firestore
                        .collection('orders')
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
                                Icons.shopping_bag_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: TSizes.spaceBtwItems),
                              Text(
                                'No pending orders',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: TSizes.spaceBtwItems / 2),
                              Text(
                                'Orders will appear here when customers place them',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      // Filter orders where current user is the seller and status is not closed/cancelled
                      final currentUserId = _firebaseService.currentUser?.uid;
                      final pendingOrders = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'] ?? 'pending';

                        // Check if status is not closed or cancelled
                        if (status == 'closed' || status == 'cancelled') {
                          return false;
                        }

                        // Check if current user is the seller in any of the items
                        final items = data['items'] as List<dynamic>? ?? [];
                        return items.any((item) {
                          final itemData = item as Map<String, dynamic>;
                          return itemData['sellerUid'] == currentUserId;
                        });
                      }).toList();

                      if (pendingOrders.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 64,
                                color: Colors.green,
                              ),
                              SizedBox(height: TSizes.spaceBtwItems),
                              Text(
                                'All orders processed',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: TSizes.spaceBtwItems / 2),
                              Text(
                                'No pending orders to process',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: pendingOrders.length,
                        itemBuilder: (context, index) {
                          final doc = pendingOrders[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildPendingOrderCard(context, doc.id, data);
                        },
                      );
                    },
                  ),
                ),
                // Auction Items Tab - Empty for now
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gavel, size: 64, color: Colors.grey),
                      SizedBox(height: TSizes.spaceBtwItems),
                      Text(
                        'Auction Items',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: TSizes.spaceBtwItems / 2),
                      Text(
                        'Coming soon...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
