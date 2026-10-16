import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/features/shop/presentation/views/order_detail_view.dart';
import 'package:utmmart/features/shop/presentation/widgets/order_summary_tile.dart';

class OrdersList extends StatelessWidget {
  final List<QueryDocumentSnapshot> orders;

  const OrdersList({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderSummaryTile(
          order: order,
          onTap: () => THelperFunctions.navigateToScreen(
            context,
            OrderDetailView(orderId: order.id),
          ),
        );
      },
    );
  }
}
