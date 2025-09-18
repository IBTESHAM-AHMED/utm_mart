import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/features/shop/presentation/widgets/orders_list.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/services/firebase_service.dart';
import 'package:iconsax/iconsax.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

enum OrderCategory { all, buy, auction }

enum OrderStatusFilter { all, pending, approved, shipped, received, closed }

class _OrdersViewState extends State<OrdersView>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = sl<FirebaseService>();
  late TabController _tabController;
  OrderStatusFilter _selectedStatus = OrderStatusFilter.all;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          title: Text(
            "My Orders",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
      body: Column(
        children: [
          // Compact Header with Tabs and Filter Button
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: TSizes.defaultSpace,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Tabs and Filter Button Row
                Row(
                  children: [
                    // Tabs
                    Expanded(
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: false,
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.grey[600],
                        indicatorColor: Theme.of(context).primaryColor,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                        tabs: const [
                          Tab(text: "All Orders"),
                          Tab(text: "Buy Orders"),
                          Tab(text: "Auctions"),
                        ],
                      ),
                    ),
                    // Filter Button
                    Container(
                      margin: const EdgeInsets.only(left: TSizes.sm),
                      child: IconButton(
                        onPressed: _showFilterBottomSheet,
                        icon: Stack(
                          children: [
                            const Icon(Iconsax.filter),
                            if (_selectedStatus != OrderStatusFilter.all)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        tooltip: 'Filter by Status',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Orders List with TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(OrderCategory.all),
                _buildOrdersList(OrderCategory.buy),
                _buildOrdersList(OrderCategory.auction),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Show filter bottom sheet
  void _showFilterBottomSheet() {
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
                if (_selectedStatus != OrderStatusFilter.all)
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedStatus = OrderStatusFilter.all);
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
                _buildStatusChip('All', OrderStatusFilter.all, Iconsax.menu),
                _buildStatusChip(
                  'Pending',
                  OrderStatusFilter.pending,
                  Iconsax.clock,
                ),
                _buildStatusChip(
                  'Approved',
                  OrderStatusFilter.approved,
                  Iconsax.tick_circle,
                ),
                _buildStatusChip(
                  'Shipped',
                  OrderStatusFilter.shipped,
                  Iconsax.ship,
                ),
                _buildStatusChip(
                  'Received',
                  OrderStatusFilter.received,
                  Iconsax.box,
                ),
                _buildStatusChip(
                  'Completed',
                  OrderStatusFilter.closed,
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

  Widget _buildStatusChip(
    String label,
    OrderStatusFilter status,
    IconData icon,
  ) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedStatus = status);
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

  // Build orders list for specific category
  Widget _buildOrdersList(OrderCategory category) {
    return Padding(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firebaseService.firestore
            .collection('orders')
            .where('customerId', isEqualTo: _firebaseService.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // Filter and sort orders
          final filteredOrders = _filterOrders(snapshot.data!.docs, category);

          if (filteredOrders.isEmpty) {
            return _buildEmptyState(isFiltered: true);
          }

          return OrdersList(orders: filteredOrders);
        },
      ),
    );
  }

  List<QueryDocumentSnapshot> _filterOrders(
    List<QueryDocumentSnapshot> orders,
    OrderCategory category,
  ) {
    var filteredOrders = orders.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // Filter by category (buy/auction)
      if (category != OrderCategory.all) {
        final isAuctionOrder = data['isAuctionOrder'] == true;
        if (category == OrderCategory.auction && !isAuctionOrder) {
          return false;
        }
        if (category == OrderCategory.buy && isAuctionOrder) {
          return false;
        }
      }

      // Filter by status
      if (_selectedStatus != OrderStatusFilter.all) {
        final status = data['status'] ?? 'pending';
        final statusMatch = _selectedStatus.toString().split('.').last;
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

  Widget _buildEmptyState({bool isFiltered = false}) {
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
                : 'Your orders will appear here',
            style: const TextStyle(color: Colors.grey),
          ),
          if (isFiltered) ...[
            const SizedBox(height: TSizes.spaceBtwItems),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedStatus = OrderStatusFilter.all;
                  _tabController.animateTo(0); // Go to "All Orders" tab
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
