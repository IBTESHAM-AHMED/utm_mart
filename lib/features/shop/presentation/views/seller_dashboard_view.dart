import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/services/firebase_service.dart';
import 'package:utmmart/features/shop/presentation/widgets/seller_orders_list.dart';

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
              Tab(text: "To Sell"),
              Tab(text: "Auction Items"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // To Sell Tab - Orders where current user is seller
                Padding(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firebaseService.firestore
                        .collection('orders')
                        .where(
                          'items',
                          arrayContains: {
                            'sellerUid': _firebaseService.currentUser?.uid,
                          },
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
                                Icons.shopping_bag_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: TSizes.spaceBtwItems),
                              Text(
                                'No orders to sell',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: TSizes.spaceBtwItems / 2),
                              Text(
                                'Orders from your items will appear here',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      return SellerOrdersList(orders: snapshot.data!.docs);
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
