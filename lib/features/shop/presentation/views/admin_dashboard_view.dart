import 'package:flutter/material.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/features/shop/data/models/product_model.dart';
import 'package:utmmart/features/shop/data/models/order_model.dart';
import 'package:utmmart/features/shop/data/models/category_model.dart';
import 'package:utmmart/features/shop/domain/repository/shop_repo.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ShopRepo _shopRepo = sl<ShopRepo>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: dark ? TColors.dark : TColors.white,
        foregroundColor: dark ? TColors.white : TColors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddProductDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Cards
          _buildStatsCards(),

          // Tab Bar
          Container(
            color: dark ? TColors.dark : TColors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: TColors.primary,
              unselectedLabelColor: dark ? TColors.grey : TColors.darkGrey,
              indicatorColor: TColors.primary,
              tabs: const [
                Tab(text: 'Products'),
                Tab(text: 'Orders'),
                Tab(text: 'Categories'),
                Tab(text: 'Analytics'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(),
                _buildOrdersTab(),
                _buildCategoriesTab(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Products',
              '0',
              Icons.inventory,
              TColors.primary,
            ),
          ),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: _buildStatCard(
              'Total Orders',
              '0',
              Icons.shopping_cart,
              TColors.success,
            ),
          ),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: _buildStatCard(
              'Revenue',
              '\$0',
              Icons.attach_money,
              TColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(TSizes.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: TSizes.xs),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return StreamBuilder<List<ProductModel>>(
      stream: _shopRepo.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return const Center(
            child: Text('No products yet. Add your first product!'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(TSizes.md),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductCard(product);
          },
        );
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: product.images.isNotEmpty
              ? NetworkImage(product.images.first)
              : null,
          child: product.images.isEmpty ? const Icon(Icons.image) : null,
        ),
        title: Text(product.name),
        subtitle: Text(
          '${product.category} • \$${product.price} • Stock: ${product.stockQuantity}',
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: TSizes.sm),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: TColors.error),
                  SizedBox(width: TSizes.sm),
                  Text('Delete', style: TextStyle(color: TColors.error)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditProductDialog(context, product);
            } else if (value == 'delete') {
              _showDeleteProductDialog(context, product);
            }
          },
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    return StreamBuilder<List<OrderModel>>(
      stream: _shopRepo.getOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return const Center(child: Text('No orders yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(TSizes.md),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      child: ListTile(
        title: Text('Order #${order.id?.substring(0, 8)}'),
        subtitle: Text(
          '${order.customerName} • \$${order.total} • ${order.statusDisplayText}',
        ),
        trailing: Chip(
          label: Text(order.statusDisplayText),
          backgroundColor: _getStatusColor(order.status),
        ),
        onTap: () => _showOrderDetailsDialog(context, order),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return TColors.warning;
      case OrderStatus.confirmed:
        return TColors.info;
      case OrderStatus.processing:
        return TColors.primary;
      case OrderStatus.shipped:
        return TColors.secondary;
      case OrderStatus.delivered:
        return TColors.success;
      case OrderStatus.cancelled:
        return TColors.error;
      case OrderStatus.returned:
        return TColors.darkGrey;
      case OrderStatus.refunded:
        return TColors.darkGrey;
    }
  }

  Widget _buildCategoriesTab() {
    return StreamBuilder<List<CategoryModel>>(
      stream: _shopRepo.getCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final categories = snapshot.data ?? [];

        if (categories.isEmpty) {
          return const Center(
            child: Text('No categories yet. Add your first category!'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(TSizes.md),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryCard(category);
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return Card(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(category.imageUrl),
          child: category.imageUrl.isEmpty ? const Icon(Icons.category) : null,
        ),
        title: Text(category.name),
        subtitle: Text('${category.productCount} products'),
        trailing: Switch(
          value: category.isActive,
          onChanged: (value) {
            // TODO: Implement category activation/deactivation
          },
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return const Padding(
      padding: EdgeInsets.all(TSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: TSizes.md),
          Text('Analytics features coming soon...'),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    // TODO: Implement add product dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add product feature coming soon!')),
    );
  }

  void _showEditProductDialog(BuildContext context, ProductModel product) {
    // TODO: Implement edit product dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit product feature coming soon!')),
    );
  }

  void _showDeleteProductDialog(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(product.id.toString());
            },
            child: const Text('Delete', style: TextStyle(color: TColors.error)),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(String productId) async {
    try {
      await _shopRepo.deleteProduct(productId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting product: $e')));
      }
    }
  }

  void _showOrderDetailsDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order.id?.substring(0, 8)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${order.customerName}'),
            Text('Email: ${order.customerEmail}'),
            Text('Phone: ${order.customerPhone}'),
            Text('Total: \$${order.total}'),
            Text('Status: ${order.statusDisplayText}'),
            Text('Payment: ${order.paymentStatusDisplayText}'),
            const SizedBox(height: TSizes.sm),
            const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...order.items.map(
              (item) => Text(
                '• ${item.productName} x${item.quantity} - \$${item.total}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
