import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/core/enums/status.dart';
import 'package:utmmart/features/auction/data/models/auction_model.dart';

class AuctionDetailView extends StatefulWidget {
  final AuctionModel auction;

  const AuctionDetailView({super.key, required this.auction});

  @override
  State<AuctionDetailView> createState() => _AuctionDetailViewState();
}

class _AuctionDetailViewState extends State<AuctionDetailView> {
  final TextEditingController _bidController = TextEditingController();

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          hasArrowBack: true,
          title: const Text('Auction Details'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TSizes.productImageRadius),
                image: DecorationImage(
                  image: NetworkImage(widget.auction.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Title
            Text(
              widget.auction.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: TSizes.spaceBtwItems / 2),

            // Category and Seller
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TSizes.sm,
                    vertical: TSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: TColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TSizes.sm),
                    border: Border.all(color: TColors.primary),
                  ),
                  child: Text(
                    widget.auction.category,
                    style: TextStyle(
                      color: TColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems),
                Text(
                  'by ${widget.auction.sellerName}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Description
            Text(
              'Description',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: TSizes.spaceBtwItems / 2),
            Text(
              widget.auction.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Price Information
            Container(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                color: THelperFunctions.isDarkMode(context)
                    ? TColors.dark
                    : TColors.light,
                borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current Bid',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '\$${widget.auction.currentBid.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: TColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems / 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Starting Price',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '\$${widget.auction.startingPrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (widget.auction.buyNowPrice != null) ...[
                    const SizedBox(height: TSizes.spaceBtwItems / 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Buy Now Price',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '\$${widget.auction.buyNowPrice!.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Time Remaining
            Container(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                color: widget.auction.isActive
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                border: Border.all(
                  color: widget.auction.isActive ? Colors.green : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.auction.isActive
                        ? Iconsax.clock
                        : Iconsax.close_circle,
                    color: widget.auction.isActive ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems / 2),
                  Text(
                    widget.auction.isActive
                        ? 'Time Remaining: ${_formatTimeRemaining(widget.auction.timeRemaining)}'
                        : 'Auction Ended',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: widget.auction.isActive
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Bidding Section (if active)
            if (widget.auction.isActive) ...[
              Text(
                'Place a Bid',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: TSizes.spaceBtwItems / 2),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bidController,
                      decoration: InputDecoration(
                        labelText: 'Bid Amount',
                        hintText: 'Enter your bid',
                        border: const OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement bid placement
                      THelperFunctions.showSnackBar(
                        context: context,
                        message: 'Bid functionality coming soon!',
                        type: SnackBarType.info,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary,
                    ),
                    child: const Text(
                      'Place Bid',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              if (widget.auction.buyNowPrice != null) ...[
                const SizedBox(height: TSizes.spaceBtwItems),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement buy now
                      THelperFunctions.showSnackBar(
                        context: context,
                        message: 'Buy now functionality coming soon!',
                        type: SnackBarType.info,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text(
                      'Buy Now - \$${widget.auction.buyNowPrice!.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} days, ${duration.inHours % 24} hours';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hours, ${duration.inMinutes % 60} minutes';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minutes';
    } else {
      return 'Less than a minute';
    }
  }
}
