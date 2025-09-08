import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/features/shop/presentation/widgets/order_list_item.dart';

class OrdersList extends StatelessWidget {
  final List<QueryDocumentSnapshot> orders;

  const OrdersList({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderListItem(order: order);
      },
      separatorBuilder: (context, index) =>
          const SizedBox(height: TSizes.spaceBtwItems),
      itemCount: orders.length,
    );
  }
}
