import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/features/auction/data/models/auction_model.dart';
import 'package:utmmart/features/auction/data/services/auction_firestore_service.dart';
import 'package:utmmart/features/auction/presentation/views/create_auction_view.dart';
import 'package:utmmart/features/auction/presentation/views/auction_detail_view.dart';

class AuctionView extends StatefulWidget {
  const AuctionView({super.key});

  @override
  State<AuctionView> createState() => _AuctionViewState();
}

class _AuctionViewState extends State<AuctionView> {
  final AuctionFirestoreService _auctionService = sl<AuctionFirestoreService>();
  final TextEditingController _searchController = TextEditingController();

  // Filter variables
  String _selectedCategory = 'All';
  String _sortBy = 'createdAt'; // createdAt, endTime, currentBid
  bool _sortAscending = false;

  final List<String> _categories = [
    'All',
    'Electronics',
    'Clothing',
    'Books',
    'Home',
    'Sports',
    'Beauty',
    'Art',
    'Collectibles',
    'Vehicle',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    setState(() {});
  }

  List<AuctionModel> _applyFilters(List<AuctionModel> auctions) {
    final query = _searchController.text.toLowerCase();

    var filteredAuctions = auctions.where((auction) {
      // Search filter
      final matchesSearch =
          query.isEmpty ||
          auction.title.toLowerCase().contains(query) ||
          auction.description.toLowerCase().contains(query) ||
          auction.category.toLowerCase().contains(query);

      // Category filter
      final matchesCategory =
          _selectedCategory == 'All' || auction.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    // Apply sorting
    filteredAuctions.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'endTime':
          comparison = a.endTime.compareTo(b.endTime);
          break;
        case 'currentBid':
          comparison = a.currentBid.compareTo(b.currentBid);
          break;
        case 'createdAt':
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filteredAuctions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          hasArrowBack: true,
          title: const Text('Auctions'),
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search auctions...',
                    prefixIcon: const Icon(Iconsax.search_normal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        TSizes.borderRadiusLg,
                      ),
                    ),
                    filled: true,
                    fillColor: THelperFunctions.isDarkMode(context)
                        ? TColors.dark
                        : TColors.light,
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwItems),

                // Filter Row
                Row(
                  children: [
                    // Category Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              TSizes.borderRadiusLg,
                            ),
                          ),
                          filled: true,
                          fillColor: THelperFunctions.isDarkMode(context)
                              ? TColors.dark
                              : TColors.light,
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: TSizes.spaceBtwItems),

                    // Sort Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        decoration: InputDecoration(
                          labelText: 'Sort by',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              TSizes.borderRadiusLg,
                            ),
                          ),
                          filled: true,
                          fillColor: THelperFunctions.isDarkMode(context)
                              ? TColors.dark
                              : TColors.light,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'createdAt',
                            child: Text('Newest'),
                          ),
                          DropdownMenuItem(
                            value: 'endTime',
                            child: Text('Ending Soon'),
                          ),
                          DropdownMenuItem(
                            value: 'currentBid',
                            child: Text('Highest Bid'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _sortBy = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Auctions List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _auctionService.getActiveAuctionsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
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
                          'Be the first to create an auction!',
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

                // Sort by createdAt descending by default
                auctions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                final filteredAuctions = _applyFilters(auctions);

                return ListView.builder(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  itemCount: filteredAuctions.length,
                  itemBuilder: (context, index) {
                    final auction = filteredAuctions[index];
                    return _buildAuctionCard(auction);
                  },
                );
              },
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

  Widget _buildAuctionCard(AuctionModel auction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Auction Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: TColors.grey.withOpacity(0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Image.network(
                        auction.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: TColors.grey.withOpacity(0.1),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: TColors.grey.withOpacity(0.1),
                            child: const Icon(Icons.image_not_supported),
                          );
                        },
                      ),
                      // Category badge
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: TColors.primary.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            auction.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Auction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Auction Title
                    Text(
                      auction.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Auction Description
                    Text(
                      auction.description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: TColors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Current Bid and Starting Price Row
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: TColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Current: \$${auction.currentBid.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: TColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Start: \$${auction.startingPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Seller, Time Remaining and Status Row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'by ${auction.sellerName}',
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: auction.isActive
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatTimeRemaining(auction.timeRemaining),
                            style: TextStyle(
                              color: auction.isActive
                                  ? Colors.orange
                                  : Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: auction.isActive
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            auction.isActive ? 'Active' : 'Ended',
                            style: TextStyle(
                              color: auction.isActive
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d left';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h left';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m left';
    } else {
      return 'Ending soon';
    }
  }
}
