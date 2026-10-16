import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:utmmart/core/common/view_models/section_heading_view_model.dart';
import 'package:utmmart/core/common/widgets/section_heading.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/features/auction/data/models/auction_model.dart';
import 'package:utmmart/features/auction/data/services/auction_firestore_service.dart';
import 'package:utmmart/features/auction/presentation/views/auction_detail_view.dart';
import 'package:utmmart/features/auction/presentation/views/auction_view.dart';

/// Home page section listing auctions that are still running.
/// Renders nothing when there are none.
class LiveAuctionsSection extends StatefulWidget {
  const LiveAuctionsSection({super.key});

  @override
  State<LiveAuctionsSection> createState() => _LiveAuctionsSectionState();
}

class _LiveAuctionsSectionState extends State<LiveAuctionsSection> {
  static const _maxShown = 3;

  final AuctionFirestoreService _auctionService = sl<AuctionFirestoreService>();
  late final Stream<QuerySnapshot> _stream = _auctionService
      .getActiveAuctionsStream();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs;
        if (docs == null) return const SizedBox.shrink();

        final auctions =
            docs
                .map((doc) => AuctionModel.fromFirestore(doc))
                .where((a) => !a.hasEnded)
                .toList()
              ..sort((a, b) => a.endTime.compareTo(b.endTime));
        if (auctions.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SectionHeading(
                sectionHeadingModel: SectionHeadingModel(
                  title: 'Live Auctions',
                  showActionButton: true,
                  textColor: TColors.primary,
                  actionButtonOnPressed: () {
                    THelperFunctions.navigateToScreen(
                      context,
                      const AuctionView(),
                    );
                  },
                  actionButtonTitle: 'View All',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final auction in auctions.take(_maxShown)) ...[
                    _buildCard(auction),
                    const SizedBox(height: TSizes.spaceBtwItems),
                  ],
                ],
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),
          ],
        );
      },
    );
  }

  String _timeLeft(AuctionModel auction) {
    final left = auction.endTime.difference(DateTime.now());
    if (left.inDays > 0) return '${left.inDays}d ${left.inHours % 24}h left';
    if (left.inHours > 0) return '${left.inHours}h ${left.inMinutes % 60}m left';
    return '${left.inMinutes.clamp(0, 59)}m left';
  }

  /// Photo shown at its own aspect ratio (never stretched or cropped). Any
  /// leftover space is filled with a blurred copy of the same photo.
  Widget _buildImage(String url) {
    final placeholder = Container(
      color: TColors.grey.withValues(alpha: 0.1),
      child: const Center(child: Icon(Icons.image_not_supported)),
    );
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            ),
          ),
          Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => placeholder,
          ),
        ],
      ),
    );
  }

  Widget _buildCard(AuctionModel auction) {
    final muted = THelperFunctions.mutedTextColor(context);
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () => THelperFunctions.navigateToScreen(
        context,
        AuctionDetailView(auction: auction),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TSizes.productImageRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(auction.imageUrl),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auction.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'RM${auction.currentBid.toStringAsFixed(2)}',
                          style: textTheme.titleMedium?.copyWith(
                            color: TColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.timer_outlined, size: 16, color: muted),
                      const SizedBox(width: 4),
                      Text(
                        _timeLeft(auction),
                        style: textTheme.bodySmall?.copyWith(color: muted),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
