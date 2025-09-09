import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmmart/core/common/view_models/grid_layout_view_model.dart';
import 'package:utmmart/core/common/view_models/section_heading_view_model.dart';
import 'package:utmmart/core/common/widgets/section_heading.dart';
import 'package:utmmart/core/cubits/banner_carousel_slider_cubit_cubit/banner_carousel_slider_cubit.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/features/auth/presentation/widgets/grid_layout.dart';
import 'package:utmmart/features/shop/data/models/store_item_model.dart';
import 'package:utmmart/features/shop/data/services/store_firestore_service.dart';
import 'package:utmmart/features/shop/presentation/views/store_view.dart';
import 'package:utmmart/features/shop/presentation/views/store_item_detail_view.dart';
import 'package:utmmart/features/shop/presentation/widgets/home_header_section.dart';
import 'package:utmmart/features/shop/presentation/widgets/promo_banner_carousel_slider.dart';

class HomeViewShimmer extends StatelessWidget {
  const HomeViewShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Shimmer.fromColors(
      baseColor: dark ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: dark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Column(
        children: [
          // Header Section Shimmer
          Container(
            height: 60,
            padding: const EdgeInsets.all(TSizes.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwSections),

          // Banner Carousel Shimmer
          Container(
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwSections),

          // Section Heading Shimmer
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TSizes.defaultSpace,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 120, height: 20, color: Colors.white),
                Container(width: 80, height: 20, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),

          // Grid Layout Shimmer
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: TSizes.defaultSpace,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: TSizes.gridViewSpacing,
              crossAxisSpacing: TSizes.gridViewSpacing,
              mainAxisExtent: 288,
            ),
            itemCount: 4,
            itemBuilder: (_, __) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(TSizes.productImageRadius),
              ),
              child: Column(
                children: [
                  // Product Image Shimmer
                  Expanded(
                    flex: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          TSizes.productImageRadius,
                        ),
                      ),
                    ),
                  ),
                  // Product Details Shimmer
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(TSizes.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(height: TSizes.spaceBtwItems / 2),
                          Container(
                            width: 100,
                            height: 16,
                            color: Colors.white,
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 60,
                                height: 20,
                                color: Colors.white,
                              ),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final StoreFirestoreService _storeService = sl<StoreFirestoreService>();
  final TextEditingController _searchController = TextEditingController();

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

  List<StoreItemModel> _applyFilters(List<StoreItemModel> items) {
    final query = _searchController.text.toLowerCase();

    return items.where((item) {
      final matchesSearch =
          query.isEmpty ||
          item.itemName.toLowerCase().contains(query) ||
          item.itemBrand.toLowerCase().contains(query);
      return matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              HomeHeaderSection(searchController: _searchController),
              const SizedBox(height: TSizes.spaceBtwSections),
              BlocProvider(
                create: (context) => BannerCarouselSliderCubit(),
                child: const PromoBannerCarouselSlider(),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SectionHeading(
                  sectionHeadingModel: SectionHeadingModel(
                    title: "Todays Pick",
                    showActionButton: true,
                    textColor: TColors.primary,
                    actionButtonOnPressed: () {
                      THelperFunctions.navigateToScreen(
                        context,
                        const StoreView(),
                      );
                    },
                    actionButtonTitle: "View All",
                  ),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              StreamBuilder<QuerySnapshot>(
                stream: _storeService.getStoreItemsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const HomeViewShimmer();
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No items available'));
                  }

                  final items = snapshot.data!.docs
                      .map((doc) => StoreItemModel.fromFirestore(doc))
                      .where(
                        (item) => item.itemStock > 0,
                      ) // Only show items with stock
                      .toList();

                  final filteredItems = _applyFilters(items);

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: TSizes.gridViewSpacing,
                            crossAxisSpacing: TSizes.gridViewSpacing,
                            childAspectRatio: 0.75,
                          ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return _buildStoreItemCard(item);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreItemCard(StoreItemModel item) {
    return GestureDetector(
      onTap: () {
        THelperFunctions.navigateToScreen(
          context,
          StoreItemDetailView(item: item),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TSizes.productImageRadius),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(TSizes.productImageRadius),
                    topRight: Radius.circular(TSizes.productImageRadius),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(item.itemImageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Item Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Item Name
                    Text(
                      item.itemName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Item Brand
                    Text(
                      item.itemBrand,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '\$${item.itemPrice.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: TColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        Text(
                          '${item.itemStock}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
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
}
