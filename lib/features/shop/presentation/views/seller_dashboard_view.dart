import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/services/firebase_service.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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

  // Helper method to get description from various possible field names
  String _getDescription(Map<String, dynamic> data) {
    final description =
        data['itemDescription'] ??
        data['description'] ??
        data['desc'] ??
        data['details'] ??
        '';

    // Truncate long descriptions for display
    if (description.length > 50) {
      return '${description.substring(0, 50)}...';
    }
    return description.isEmpty ? 'No description' : description;
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

  // Add new item functionality
  void _addNewItem(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final descriptionController = TextEditingController();
    final imageUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Item'),
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
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter an item name'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              await _createItem({
                'itemName': nameController.text.trim(),
                'itemPrice': double.tryParse(priceController.text) ?? 0.0,
                'itemStock': int.tryParse(stockController.text) ?? 0,
                'itemDescription': descriptionController.text.trim(),
                'itemImageUrl': imageUrlController.text.trim(),
                'sellerUid': _firebaseService.currentUser?.uid ?? '',
                'createdAt': DateTime.now().toIso8601String(),
                'updatedAt': DateTime.now().toIso8601String(),
              });
              Navigator.pop(context);
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  // Create new item in Firestore
  Future<void> _createItem(Map<String, dynamic> itemData) async {
    try {
      await _firebaseService.firestore.collection('store').add(itemData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          actions: [
            IconButton(
              onPressed: () => _addNewItem(context),
              icon: const Icon(Icons.add),
              tooltip: 'Add New Item',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "My Store"),
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

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
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
