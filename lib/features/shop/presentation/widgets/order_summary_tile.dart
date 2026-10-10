import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';

/// One compact row per order (thumbnail, title, status, total). The full
/// details open on tap via [onTap].
class OrderSummaryTile extends StatelessWidget {
  const OrderSummaryTile({super.key, required this.order, required this.onTap});

  final DocumentSnapshot order;
  final VoidCallback onTap;

  static (String, Color) statusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return ('Approved', Colors.blue);
      case 'shipped':
        return ('Shipped', Colors.purple);
      case 'received':
        return ('Received', Colors.teal);
      case 'closed':
        return ('Completed', Colors.green);
      case 'cancelled':
        return ('Cancelled', Colors.red);
      default:
        return ('Pending', Colors.orange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = order.data() as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? [];
    final first = items.isNotEmpty ? items.first as Map<String, dynamic> : null;
    final isAuction = data['isAuctionOrder'] == true;
    final (statusText, statusColor) = statusStyle(data['status'] ?? 'pending');
    final total = (data['total'] ?? 0.0).toDouble();
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final muted = THelperFunctions.mutedTextColor(context);
    final tagColor = isAuction ? Colors.purple : Colors.green;
    final title = first?['itemName'] ?? 'Order';
    final extra = items.length > 1 ? ' +${items.length - 1} more' : '';
    final imageUrl = (first?['itemImageUrl'] ?? '') as String;
    final when = createdAt != null
        ? ' • ${DateFormat('dd MMM, HH:mm').format(createdAt)}'
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(TSizes.sm),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isEmpty
                    ? _placeholder(muted)
                    : Image.network(
                        imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(muted),
                      ),
              ),
              const SizedBox(width: TSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$title$extra',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _chip(isAuction ? 'AUCTION' : 'BUY', tagColor),
                        const SizedBox(width: 6),
                        _chip(statusText, statusColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${order.id.substring(0, 8)}$when',
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TSizes.xs),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RM${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Icon(Icons.chevron_right, color: muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(Color muted) => Container(
    width: 56,
    height: 56,
    color: muted.withValues(alpha: 0.2),
    child: const Icon(Icons.shopping_bag_outlined),
  );

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}
