import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmmart/core/common/view_models/app_bar_view_model.dart';
import 'package:utmmart/core/common/widgets/app_bar.dart';
import 'package:utmmart/core/utils/constants/colors.dart';
import 'package:utmmart/core/utils/constants/sizes.dart';
import 'package:utmmart/core/utils/helpers/helper_functions.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/features/shop/data/models/store_item_model.dart';
import 'package:utmmart/features/shop/data/services/store_firestore_service.dart';
import 'package:utmmart/features/shop/presentation/views/cart_view.dart';
import 'package:utmmart/features/shop/presentation/views/add_store_item_view.dart';
import 'package:utmmart/features/shop/presentation/views/store_item_detail_view.dart';
import 'package:utmmart/features/shop/presentation/widgets/cart_counter_widget.dart';

class StoreView extends StatefulWidget {
  const StoreView({super.key});

  @override
  State<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> {
  final StoreFirestoreService _storeService = sl<StoreFirestoreService>();
  final TextEditingController _searchController = TextEditingController();

  // Filter variables
  String _selectedCategory = 'All';
  String _selectedBrand = 'All';
  double _minPrice = 0;
  double _maxPrice = 10000;
  String _sortBy = 'name'; // name, price, stock
  bool _sortAscending = true;

  final List<String> _categories = [
    'All',
    'Electronics',
    'Clothing',
    'Books',
    'Home',
    'Sports',
    'Beauty',
    'Other',
  ];
  final List<String> _brands = ['All']; // Will be populated dynamically

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
    // Trigger rebuild to update StreamBuilder with new filters
    setState(() {});
  }

  // New method for applying filters in StreamBuilder
  List<StoreItemModel> _applyFilters(List<StoreItemModel> items) {
    final query = _searchController.text.toLowerCase();

    var filteredItems = items.where((item) {
      // Search filter
      final matchesSearch =
          query.isEmpty ||
          item.itemName.toLowerCase().contains(query) ||
          item.itemBrand.toLowerCase().contains(query);

      // Category filter
      final matchesCategory =
          _selectedCategory == 'All' || item.itemCategory == _selectedCategory;

      // Brand filter
      final matchesBrand =
          _selectedBrand == 'All' || item.itemBrand == _selectedBrand;

      // Price filter
      final matchesPrice =
          item.itemPrice >= _minPrice && item.itemPrice <= _maxPrice;

      return matchesSearch && matchesCategory && matchesBrand && matchesPrice;
    }).toList();

    // Apply sorting
    filteredItems.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'price':
          comparison = a.itemPrice.compareTo(b.itemPrice);
          break;
        case 'stock':
          comparison = a.itemStock.compareTo(b.itemStock);
          break;
        case 'name':
        default:
          comparison = a.itemName.compareTo(b.itemName);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filteredItems;
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          title: Text(
            "Store",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          actions: [
            CartCounterWidget(
              onTap: () {
                THelperFunctions.navigateToScreen(context, const CartView());
              },
              iconColor: dark ? TColors.white : TColors.dark,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by item name or brand...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: _showFilterDialog,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: TColors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: TColors.primary),
                ),
              ),
            ),
          ),

          // Filter Chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(
              horizontal: TSizes.defaultSpace,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Category: $_selectedCategory'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Brand: $_selectedBrand'),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Price: \$${_minPrice.toInt()}-\$${_maxPrice.toInt()}',
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Sort: $_sortBy ${_sortAscending ? '↑' : '↓'}',
                  ),
                ],
              ),
            ),
          ),

          // Items List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _storeService.getStoreItemsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                // Convert documents to StoreItemModel and filter out items with 0 stock
                final items = snapshot.data!.docs
                    .map((doc) => StoreItemModel.fromFirestore(doc))
                    .where((item) => item.itemStock > 0)
                    .toList();

                if (items.isEmpty) {
                  return _buildEmptyState();
                }

                // Apply search and filter
                final filteredItems = _applyFilters(items);

                return ListView.builder(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    return _buildStoreItemCard(filteredItems[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewItem,
        backgroundColor: TColors.primary,
        child: const Icon(Icons.add, color: TColors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: TColors.primary.withOpacity(0.1),
      side: BorderSide(color: TColors.primary.withOpacity(0.3)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 80, color: TColors.grey),
          const SizedBox(height: 16),
          Text(
            'No items in store yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: TColors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first item',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: TColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreItemCard(StoreItemModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openItemDetail(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: TColors.grey.withOpacity(0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.itemImageUrl.isNotEmpty
                      ? Image.network(
                          item.itemImageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: TColors.grey.withOpacity(0.1),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: TColors.grey.withOpacity(0.1),
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        )
                      : Container(
                          color: TColors.grey.withOpacity(0.1),
                          child: const Icon(Icons.image),
                        ),
                ),
              ),

              const SizedBox(width: 16),

              // Item Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Name
                    Text(
                      item.itemName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Item Description
                    Text(
                      item.itemDescription,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: TColors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Price and Stock Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: TColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.displayPrice,
                            style: TextStyle(
                              color: TColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: item.itemStock > 0
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Stock: ${item.itemStock}',
                            style: TextStyle(
                              color: item.itemStock > 0
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Brand and Category Row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Brand: ${item.itemBrand}',
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          item.itemCategory,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: TColors.primary,
                                fontWeight: FontWeight.w500,
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

  void _openItemDetail(StoreItemModel item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => StoreItemDetailView(item: item)),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Items'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Filter
                    const Text(
                      'Category:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          _selectedCategory = newValue!;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Brand Filter
                    const Text(
                      'Brand:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: _selectedBrand,
                      isExpanded: true,
                      items: _brands.map((String brand) {
                        return DropdownMenuItem<String>(
                          value: brand,
                          child: Text(brand),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          _selectedBrand = newValue!;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Price Range
                    const Text(
                      'Price Range:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    RangeSlider(
                      values: RangeValues(_minPrice, _maxPrice),
                      min: 0,
                      max: 10000,
                      divisions: 100,
                      labels: RangeLabels(
                        '\$${_minPrice.toInt()}',
                        '\$${_maxPrice.toInt()}',
                      ),
                      onChanged: (RangeValues values) {
                        setDialogState(() {
                          _minPrice = values.start;
                          _maxPrice = values.end;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Sort Options
                    const Text(
                      'Sort By:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: _sortBy,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'name',
                                child: Text('Name'),
                              ),
                              DropdownMenuItem(
                                value: 'price',
                                child: Text('Price'),
                              ),
                              DropdownMenuItem(
                                value: 'stock',
                                child: Text('Stock'),
                              ),
                            ],
                            onChanged: (String? newValue) {
                              setDialogState(() {
                                _sortBy = newValue!;
                              });
                            },
                          ),
                        ),

                        IconButton(
                          icon: Icon(
                            _sortAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _sortAscending = !_sortAscending;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Reset filters
                    setDialogState(() {
                      _selectedCategory = 'All';
                      _selectedBrand = 'All';
                      _minPrice = 0;
                      _maxPrice = 10000;
                      _sortBy = 'name';
                      _sortAscending = true;
                    });
                  },
                  child: const Text('Reset'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _filterItems();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addNewItem() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const AddStoreItemView()),
    );
    // StreamBuilder will automatically refresh the list
  }
}
