import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/features/auction/data/models/auction_model.dart';
import 'package:utmmart/features/auction/data/services/auction_firestore_service.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/features/auction/presentation/views/auction_detail_view.dart';
import 'package:utmmart/features/auction/presentation/views/create_auction_view.dart';

class SellerDashboardView extends StatefulWidget {
  const SellerDashboardView({super.key});

  @override
  State<SellerDashboardView> createState() => _SellerDashboardViewState();
}

class _SellerDashboardViewState extends State<SellerDashboardView>
    with TickerProviderStateMixin {
  final AuctionFirestoreService _auctionService = sl<AuctionFirestoreService>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TabController _tabController;
  String? _currentUserUid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserUid = user.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserUid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          hasArrowBack: true,
          title: const Text('My Auctions'),
        ),
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: THelperFunctions.isDarkMode(context)
                ? TColors.dark
                : TColors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: TColors.primary,
              unselectedLabelColor: THelperFunctions.isDarkMode(context)
                  ? TColors.grey
                  : TColors.darkGrey,
              indicatorColor: TColors.primary,
              tabs: const [
                Tab(text: 'Active Auctions'),
                Tab(text: 'Closed Auctions'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildActiveAuctionsTab(), _buildClosedAuctionsTab()],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          THelperFunctions.navigateToScreen(context, const CreateAuctionView());
        },
        backgroundColor: TColors.primary,
        child: const Icon(Iconsax.add, color: TColors.white),
      ),
    );
  }

  Widget _buildActiveAuctionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _auctionService.getUserActiveAuctionsStream(_currentUserUid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text(
                  'Error loading auctions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: TSizes.spaceBtwItems / 2),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gavel, size: 64, color: Colors.grey),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text(
                  'No active auctions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: TSizes.spaceBtwItems / 2),
                Text(
                  'Create your first auction to get started!',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final auctions = snapshot.data!.docs
            .map((doc) => AuctionModel.fromFirestore(doc))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          itemCount: auctions.length,
          itemBuilder: (context, index) {
            final auction = auctions[index];
            return _buildAuctionCard(auction, isActive: true);
          },
        );
      },
    );
  }

  Widget _buildClosedAuctionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _auctionService.getUserClosedAuctionsStream(_currentUserUid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text(
                  'Error loading auctions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: TSizes.spaceBtwItems / 2),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 64, color: Colors.grey),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text(
                  'No closed auctions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: TSizes.spaceBtwItems / 2),
                Text(
                  'Your completed auctions will appear here.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final auctions = snapshot.data!.docs
            .map((doc) => AuctionModel.fromFirestore(doc))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          itemCount: auctions.length,
          itemBuilder: (context, index) {
            final auction = auctions[index];
            return _buildAuctionCard(auction, isActive: false);
          },
        );
      },
    );
  }

  Widget _buildAuctionCard(AuctionModel auction, {required bool isActive}) {
    final highestBid = auction.highestBid;

    return Card(
      margin: const EdgeInsets.only(bottom: TSizes.md),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          THelperFunctions.navigateToScreen(
            context,
            AuctionDetailView(auction: auction),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(TSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Auction Image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: TColors.grey.withOpacity(0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        auction.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: TColors.grey.withOpacity(0.1),
                            child: const Icon(Icons.image_not_supported),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: TSizes.sm),

                  // Auction Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auction.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auction.category,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: TColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              isActive ? Iconsax.clock : Iconsax.close_circle,
                              size: 14,
                              color: isActive ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isActive ? 'Active' : 'Ended',
                              style: TextStyle(
                                color: isActive ? Colors.green : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Current Bid
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${auction.currentBid.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: TColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Current Bid',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: TSizes.sm),

              // Bidding Info
              if (highestBid != null) ...[
                Container(
                  padding: const EdgeInsets.all(TSizes.sm),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? Colors.blue : Colors.green,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isActive ? Iconsax.user : Iconsax.crown,
                        size: 16,
                        color: isActive ? Colors.blue : Colors.green,
                      ),
                      const SizedBox(width: TSizes.xs),
                      Text(
                        isActive
                            ? 'Highest bidder: ${highestBid.bidderName}'
                            : 'Winner: ${highestBid.bidderName}',
                        style: TextStyle(
                          color: isActive
                              ? Colors.blue[700]
                              : Colors.green[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TSizes.sm),
              ],

              // Time Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Started: ${_formatDate(auction.startTime)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  Text(
                    isActive
                        ? 'Ends: ${_formatDate(auction.endTime)}'
                        : 'Ended: ${_formatDate(auction.endTime)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isActive ? Colors.orange[600] : Colors.red[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

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
