import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:utmmart/core/common/widgets/primary_header_container.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/features/notifications/data/models/notification_model.dart';
import 'package:utmmart/features/notifications/data/services/notification_service.dart';
import 'package:utmmart/features/notifications/presentation/widgets/notification_item.dart';
import 'package:utmmart/features/shop/presentation/views/orders_view.dart';
import 'package:utmmart/features/auction/presentation/views/auction_detail_view.dart';
import 'package:utmmart/features/auction/data/services/auction_firestore_service.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final NotificationService _notificationService = NotificationService();
  final AuctionFirestoreService _auctionService = sl<AuctionFirestoreService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            PrimaryHeaderContainer(
              child: Column(
                children: [
                  // App Bar
                  AppBar(
                    title: Text(
                      'Notifications',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.apply(color: TColors.white),
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(
                        Iconsax.arrow_left,
                        color: TColors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),
                ],
              ),
            ),

            // Notifications List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: Column(
                  children: [
                    // Mark all as read button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'All Notifications',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () async {
                            await _notificationService.markAllAsRead();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'All notifications marked as read',
                                  ),
                                  backgroundColor: TColors.success,
                                ),
                              );
                            }
                          },
                          child: const Text('Mark All Read'),
                        ),
                      ],
                    ),
                    const SizedBox(height: TSizes.spaceBtwItems),

                    // Notifications Stream
                    Expanded(
                      child: StreamBuilder<List<NotificationModel>>(
                        stream: _notificationService.getUserNotifications(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Iconsax.notification_bing,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: TSizes.spaceBtwItems),
                                  Text(
                                    'Error loading notifications',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(
                                    height: TSizes.spaceBtwItems / 2,
                                  ),
                                  Text(
                                    snapshot.error.toString(),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          final notifications = snapshot.data ?? [];

                          if (notifications.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Iconsax.notification_bing,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: TSizes.spaceBtwItems),
                                  Text(
                                    'No Notifications',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(
                                    height: TSizes.spaceBtwItems / 2,
                                  ),
                                  Text(
                                    'You\'ll see your notifications here when you have them',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: notifications.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: TSizes.spaceBtwItems),
                            itemBuilder: (context, index) {
                              final notification = notifications[index];
                              return NotificationItem(
                                notification: notification,
                                onTap: () async {
                                  // Mark as read when tapped
                                  if (notification.status ==
                                      NotificationStatus.unread) {
                                    await _notificationService.markAsRead(
                                      notification.id,
                                    );
                                  }

                                  // Navigate based on notification type and data
                                  _handleNotificationTap(notification);
                                },
                                onDelete: () async {
                                  await _notificationService.deleteNotification(
                                    notification.id,
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Notification deleted'),
                                        backgroundColor: TColors.success,
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.orderStatusChange:
      case NotificationType.orderWaitingApproval:
        // Navigate to orders view
        THelperFunctions.navigateToScreen(context, const OrdersView());
        break;
      case NotificationType.auctionOutbid:
      case NotificationType.auctionWon:
      case NotificationType.auctionEnded:
      case NotificationType.auctionCreated:
        // Navigate to auction detail view
        final auctionId = notification.data?['auctionId'] as String?;
        if (auctionId != null) {
          _navigateToAuctionDetail(auctionId);
        } else {
          // If no auctionId, show a message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Auction details not available'),
              backgroundColor: TColors.warning,
            ),
          );
        }
        break;
      case NotificationType.general:
        // No specific navigation
        break;
    }
  }

  Future<void> _navigateToAuctionDetail(String auctionId) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Load auction data
      final auction = await _auctionService.getAuctionById(auctionId);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (auction != null) {
        // Navigate to auction detail view
        THelperFunctions.navigateToScreen(
          context,
          AuctionDetailView(auction: auction),
        );
      } else {
        // Show error if auction not found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Auction not found'),
              backgroundColor: TColors.error,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading auction: $e'),
            backgroundColor: TColors.error,
          ),
        );
      }
    }
  }
}
