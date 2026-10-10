import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/features/shop/presentation/widgets/order_list_item.dart';

/// Full details (and actions) for one of the signed-in user's own orders.
/// Streams the order so status changes show up live.
class OrderDetailView extends StatelessWidget {
  const OrderDetailView({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          hasArrowBack: true,
          title: Text(
            'Order Details',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final doc = snapshot.data!;
          if (!doc.exists) {
            return const Center(child: Text('Order not found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: OrderListItem(key: ValueKey(doc.id), order: doc),
          );
        },
      ),
    );
  }
}
