import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/core/enums/status.dart';
import 'package:utmmart/features/auction/data/models/auction_model.dart';
import 'package:utmmart/features/auction/data/services/auction_firestore_service.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/services/firebase_service.dart';

class AuctionDetailView extends StatefulWidget {
  final AuctionModel auction;

  const AuctionDetailView({super.key, required this.auction});

  @override
  State<AuctionDetailView> createState() => _AuctionDetailViewState();
}

class _AuctionDetailViewState extends State<AuctionDetailView> {
  final TextEditingController _bidController = TextEditingController();
  final AuctionFirestoreService _auctionService = sl<AuctionFirestoreService>();
  final FirebaseService _firebaseService = sl<FirebaseService>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuctionModel? _currentAuction;
  bool _isLoading = false;
  String? _currentUserUid;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _currentAuction = widget.auction;
    _getCurrentUser();
    _checkAuctionStatus();
  }

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserUid = user.uid;
      });

      // Get user name from Firestore
      try {
        final userDoc = await _firebaseService.firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _currentUserName =
                userData['fullName'] ?? userData['email'] ?? 'Unknown User';
          });
        }
      } catch (e) {
        print('Error getting user name: $e');
        setState(() {
          _currentUserName = 'Unknown User';
        });
      }
    }
  }

  Future<void> _checkAuctionStatus() async {
    if (_currentAuction == null) return;

    final now = DateTime.now();
    if (now.isAfter(_currentAuction!.endTime) &&
        _currentAuction!.status == 'active') {
      // Auction has ended, update status
      try {
        await _auctionService.endAuction(_currentAuction!.id!);
        setState(() {
          _currentAuction = _currentAuction!.copyWith(status: 'ended');
        });
      } catch (e) {
        print('Error ending auction: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentAuction == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final auction = _currentAuction!;
    final isSeller = _currentUserUid == auction.sellerUid;
    final isAuctionActive = auction.isActive;
    final highestBid = auction.highestBid;

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
                  image: NetworkImage(auction.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Title
            Text(
              auction.title,
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
                    auction.category,
                    style: TextStyle(
                      color: TColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems),
                Expanded(
                  child: Text(
                    'by ${auction.sellerName}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
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
              auction.description,
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
                        '\$${auction.currentBid.toStringAsFixed(2)}',
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
                        '\$${auction.startingPrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (auction.buyNowPrice != null) ...[
                    const SizedBox(height: TSizes.spaceBtwItems / 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Buy Now Price',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.green[600],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '\$${auction.buyNowPrice!.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.green[600],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                  // Show highest bidder if auction has ended
                  if (!isAuctionActive && highestBid != null) ...[
                    const SizedBox(height: TSizes.spaceBtwItems / 2),
                    const Divider(),
                    const SizedBox(height: TSizes.spaceBtwItems / 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Winning Bidder',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.green[600],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          highestBid.bidderName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.green[600],
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
                color: isAuctionActive
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                border: Border.all(
                  color: isAuctionActive ? Colors.green : Colors.red,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TSizes.sm,
                  vertical: TSizes.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAuctionActive ? Iconsax.clock : Iconsax.close_circle,
                      color: isAuctionActive ? Colors.green : Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: TSizes.spaceBtwItems / 2),
                    Flexible(
                      child: Text(
                        isAuctionActive
                            ? 'Time Left: ${_formatTimeRemaining(auction.timeRemaining)}'
                            : 'Auction Ended',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: isAuctionActive
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Bidding Section (if active and user is not seller)
            if (isAuctionActive && !isSeller) ...[
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
                        suffixText: 'USD',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _placeBid,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Place Bid',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
            ],

            // Buy Now Button (if active and user is not seller)
            if (isAuctionActive &&
                !isSeller &&
                auction.buyNowPrice != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _buyNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Buy Now - \$${auction.buyNowPrice!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
            ],

            // Seller message
            if (isSeller) ...[
              Container(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    const SizedBox(width: TSizes.spaceBtwItems / 2),
                    Expanded(
                      child: Text(
                        'You are the seller of this auction. You cannot place bids on your own items.',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
            ],

            // Bids History
            if (auction.bids.isNotEmpty) ...[
              Text(
                'Bidding History',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: TSizes.spaceBtwItems / 2),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: auction.bids.length,
                  itemBuilder: (context, index) {
                    final bid = auction.bids[auction.bids.length - 1 - index];
                    final isHighestBid = bid == highestBid;
                    return Container(
                      margin: const EdgeInsets.only(bottom: TSizes.sm),
                      padding: const EdgeInsets.all(TSizes.sm),
                      decoration: BoxDecoration(
                        color: isHighestBid
                            ? Colors.green.withOpacity(0.1)
                            : THelperFunctions.isDarkMode(context)
                            ? TColors.dark
                            : TColors.light,
                        borderRadius: BorderRadius.circular(TSizes.sm),
                        border: Border.all(
                          color: isHighestBid
                              ? Colors.green
                              : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bid.bidderName,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _formatBidTime(bid.timestamp),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '\$${bid.amount.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isHighestBid ? Colors.green : null,
                                    ),
                              ),
                              if (isHighestBid) ...[
                                const SizedBox(width: TSizes.xs),
                                Icon(Icons.star, color: Colors.green, size: 16),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _placeBid() async {
    if (_currentUserUid == null || _currentUserName == null) {
      THelperFunctions.showSnackBar(
        context: context,
        message: 'Please log in to place a bid',
        type: SnackBarType.error,
      );
      return;
    }

    final bidAmount = double.tryParse(_bidController.text);
    if (bidAmount == null || bidAmount <= 0) {
      THelperFunctions.showSnackBar(
        context: context,
        message: 'Please enter a valid bid amount',
        type: SnackBarType.error,
      );
      return;
    }

    if (bidAmount <= _currentAuction!.currentBid) {
      THelperFunctions.showSnackBar(
        context: context,
        message:
            'Bid must be higher than current bid of \$${_currentAuction!.currentBid.toStringAsFixed(2)}',
        type: SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bid = BidModel(
        bidderUid: _currentUserUid!,
        bidderName: _currentUserName!,
        amount: bidAmount,
        timestamp: DateTime.now(),
      );

      await _auctionService.placeBid(_currentAuction!.id!, bid);

      // Refresh auction data
      final updatedAuction = await _auctionService.getAuctionById(
        _currentAuction!.id!,
      );
      if (updatedAuction != null) {
        setState(() {
          _currentAuction = updatedAuction;
          _bidController.clear();
        });
      }

      THelperFunctions.showSnackBar(
        context: context,
        message: 'Bid placed successfully!',
        type: SnackBarType.success,
      );
    } catch (e) {
      THelperFunctions.showSnackBar(
        context: context,
        message: 'Failed to place bid: $e',
        type: SnackBarType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _buyNow() async {
    if (_currentUserUid == null || _currentUserName == null) {
      THelperFunctions.showSnackBar(
        context: context,
        message: 'Please log in to buy now',
        type: SnackBarType.error,
      );
      return;
    }

    if (_currentAuction!.buyNowPrice == null) {
      THelperFunctions.showSnackBar(
        context: context,
        message: 'Buy now is not available for this auction',
        type: SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auctionService.buyNow(
        _currentAuction!.id!,
        _currentUserUid!,
        _currentUserName!,
      );

      // Refresh auction data
      final updatedAuction = await _auctionService.getAuctionById(
        _currentAuction!.id!,
      );
      if (updatedAuction != null) {
        setState(() {
          _currentAuction = updatedAuction;
        });
      }

      THelperFunctions.showSnackBar(
        context: context,
        message: 'Item purchased successfully!',
        type: SnackBarType.success,
      );
    } catch (e) {
      THelperFunctions.showSnackBar(
        context: context,
        message: 'Failed to buy now: $e',
        type: SnackBarType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  String _formatBidTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
