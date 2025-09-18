import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/features/notifications/data/models/notification_model.dart';

class NotificationItem extends StatelessWidget {
  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final isUnread = notification.status == NotificationStatus.unread;

    return Container(
      decoration: BoxDecoration(
        color: isUnread
            ? TColors.primary.withOpacity(0.05)
            : dark
            ? TColors.darkerGrey
            : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        border: isUnread
            ? Border.all(color: TColors.primary.withOpacity(0.2))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
          child: Padding(
            padding: const EdgeInsets.all(TSizes.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getNotificationColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
                  ),
                  child: Icon(
                    _getNotificationIcon(),
                    color: _getNotificationColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems),

                // Notification Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Time
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: isUnread
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isUnread ? TColors.primary : null,
                                  ),
                            ),
                          ),
                          const SizedBox(width: TSizes.spaceBtwItems / 2),
                          Text(
                            _formatTime(notification.createdAt),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: TSizes.spaceBtwItems / 2),

                      // Message
                      Text(
                        notification.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Unread indicator
                      if (isUnread) ...[
                        const SizedBox(height: TSizes.spaceBtwItems / 2),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: TColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Delete button
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Iconsax.trash, size: 16),
                          SizedBox(width: TSizes.spaceBtwItems / 2),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.all(TSizes.spaceBtwItems / 2),
                    child: Icon(
                      Iconsax.more,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case NotificationType.orderStatusChange:
        return Iconsax.shopping_bag;
      case NotificationType.orderWaitingApproval:
        return Iconsax.clock;
      case NotificationType.auctionOutbid:
        return Iconsax.arrow_down;
      case NotificationType.auctionWon:
        return Iconsax.crown;
      case NotificationType.auctionEnded:
        return Iconsax.flag;
      case NotificationType.auctionCreated:
        return Iconsax.gift;
      case NotificationType.general:
        return Iconsax.notification;
    }
  }

  Color _getNotificationColor() {
    switch (notification.type) {
      case NotificationType.orderStatusChange:
        return Colors.green;
      case NotificationType.orderWaitingApproval:
        return Colors.orange;
      case NotificationType.auctionOutbid:
        return Colors.red;
      case NotificationType.auctionWon:
        return Colors.green;
      case NotificationType.auctionEnded:
        return Colors.grey;
      case NotificationType.auctionCreated:
        return Colors.blue;
      case NotificationType.general:
        return TColors.primary;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

