import 'package:flutter/material.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/features/auth/data/models/login_response.dart';

class VendorDashboardView extends StatefulWidget {
  final LoginUserData currentUser;

  const VendorDashboardView({super.key, required this.currentUser});

  @override
  State<VendorDashboardView> createState() => _VendorDashboardViewState();
}

class _VendorDashboardViewState extends State<VendorDashboardView>
    with TickerProviderStateMixin {
  late TabController _tabController;

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
        title: const Text('Vendor Dashboard'),
        backgroundColor: dark ? TColors.dark : TColors.white,
        foregroundColor: dark ? TColors.white : TColors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business),
            onPressed: () => _navigateToVendorSetup(),
            tooltip: 'Setup Vendor Profile',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddProduct(),
            tooltip: 'Add Product',
          ),
        ],
      ),
      body: Column(
        children: [
          // Vendor Info Card
          _buildVendorInfoCard(dark),

          // Stats Cards
          _buildStatsCards(dark),

          // Tab Bar
          Container(
            color: dark ? TColors.dark : TColors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: dark ? TColors.white : TColors.primary,
              unselectedLabelColor: dark ? TColors.grey : TColors.darkGrey,
              indicatorColor: TColors.primary,
              tabs: const [
                Tab(text: 'Products'),
                Tab(text: 'Orders'),
                Tab(text: 'Analytics'),
                Tab(text: 'Profile'),
              ],
            ),
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(),
                _buildOrdersTab(),
                _buildAnalyticsTab(),
                _buildProfileTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddProduct(),
        backgroundColor: TColors.primary,
        child: const Icon(Icons.add, color: TColors.white),
      ),
    );
  }

  Widget _buildVendorInfoCard(bool dark) {
    return Container(
      margin: const EdgeInsets.all(TSizes.defaultSpace),
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.darkGrey : TColors.light,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: TColors.primary,
            child: Text(
              widget.currentUser.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: TColors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.currentUser.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: TSizes.xs),
                Text(
                  widget.currentUser.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: dark ? TColors.grey : TColors.darkGrey,
                  ),
                ),
                const SizedBox(height: TSizes.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TSizes.sm,
                    vertical: TSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: TColors.success,
                    borderRadius: BorderRadius.circular(TSizes.xs),
                  ),
                  child: const Text(
                    'Active Seller',
                    style: TextStyle(color: TColors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(bool dark) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Products', '0', Icons.inventory, dark),
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          Expanded(
            child: _buildStatCard('Orders', '0', Icons.shopping_cart, dark),
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          Expanded(
            child: _buildStatCard('Revenue', '\$0', Icons.attach_money, dark),
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          Expanded(child: _buildStatCard('Rating', '0.0', Icons.star, dark)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, bool dark) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: dark ? TColors.darkGrey : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: TColors.primary),
          const SizedBox(height: TSizes.xs),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: dark ? TColors.grey : TColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Column(
        children: [
          // Search and Filter Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search your products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        TSizes.inputFieldRadius,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              IconButton(
                onPressed: () {
                  // TODO: Implement filter
                },
                icon: const Icon(Icons.filter_list),
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems),

          // Products List
          Expanded(child: _buildProductsList()),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    // TODO: Replace with actual BLoC implementation
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: TColors.grey),
          SizedBox(height: TSizes.spaceBtwItems),
          Text(
            'No products yet',
            style: TextStyle(fontSize: 18, color: TColors.grey),
          ),
          SizedBox(height: TSizes.xs),
          Text(
            'Add your first product to get started!',
            style: TextStyle(color: TColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: TColors.grey),
            SizedBox(height: TSizes.spaceBtwItems),
            Text(
              'No orders yet',
              style: TextStyle(fontSize: 18, color: TColors.grey),
            ),
            SizedBox(height: TSizes.xs),
            Text(
              'Orders for your products will appear here',
              style: TextStyle(color: TColors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: TColors.grey),
            SizedBox(height: TSizes.spaceBtwItems),
            Text(
              'Analytics Coming Soon',
              style: TextStyle(fontSize: 18, color: TColors.grey),
            ),
            SizedBox(height: TSizes.xs),
            Text(
              'Track your sales performance and insights',
              style: TextStyle(color: TColors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seller Profile',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Profile completion card
            Container(
              padding: const EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                color: TColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                border: Border.all(color: TColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined, color: TColors.warning),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Complete Your Profile',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Add your address to start selling products',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _navigateToVendorSetup(),
                    child: const Text('Setup'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            // Basic info
            _buildInfoSection('Basic Information', [
              _buildInfoRow('Name', widget.currentUser.name),
              _buildInfoRow('Email', widget.currentUser.email),
              _buildInfoRow('Phone', widget.currentUser.mobile),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: TSizes.spaceBtwItems),
        ...children,
        const SizedBox(height: TSizes.spaceBtwSections),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: TColors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _navigateToAddProduct() {
    // TODO: Navigate to add product screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Product screen - Coming Soon!')),
    );
  }

  void _navigateToVendorSetup() {
    // TODO: Navigate to seller setup screen
    // THelperFunctions.navigateToScreen(
    //   context,
    //   SellerProfileSetupView(currentUser: widget.currentUser),
    // );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seller Profile Setup - Coming Soon!')),
    );
  }
}
