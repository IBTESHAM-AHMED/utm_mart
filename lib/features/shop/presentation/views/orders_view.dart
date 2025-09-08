import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/features/shop/presentation/widgets/orders_list.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/services/firebase_service.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  final FirebaseService _firebaseService = sl<FirebaseService>();

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
      body: Padding(
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
                      'No orders found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: TSizes.spaceBtwItems / 2),
                    Text(
                      'Your orders will appear here',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // Sort orders by creation date (newest first)
            final sortedDocs = snapshot.data!.docs.toList()
              ..sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aCreatedAt = aData['createdAt'] as Timestamp;
                final bCreatedAt = bData['createdAt'] as Timestamp;
                return bCreatedAt.compareTo(aCreatedAt); // Descending order
              });

            return OrdersList(orders: sortedDocs);
          },
        ),
      ),
    );
  }
}
