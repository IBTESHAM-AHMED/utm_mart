import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmmart/features/shop/domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  final String? firebaseId;
  final String name;
  @override
  final String description;
  @override
  final double price;
  final double? salePrice;
  @override
  final String category;
  @override
  final String brand;
  @override
  final List<String> images;
  final int stockQuantity;
  final bool isActive;
  final bool isFeatured;
  @override
  final double rating;
  final int reviewCount;
  final String vendorId;
  @override
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? specifications;
  @override
  final List<String> tags;
  final String? sku;
  final double? weight;
  final String? weightUnit;
  final List<String>? colors;
  final List<String>? sizes;

  ProductModel({
    this.firebaseId,
    required this.name,
    required this.description,
    required this.price,
    this.salePrice,
    required this.category,
    required this.brand,
    required this.images,
    required this.stockQuantity,
    this.isActive = true,
    this.isFeatured = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.vendorId,
    required this.createdAt,
    required this.updatedAt,
    this.specifications,
    this.tags = const [],
    this.sku,
    this.weight,
    this.weightUnit,
    this.colors,
    this.sizes,
  }) : super(
         id: int.tryParse(firebaseId ?? '0') ?? 0,
         title: name,
         description: description,
         category: category,
         price: price,
         discountPercentage: salePrice != null
             ? ((price - salePrice) / price * 100)
             : 0.0,
         rating: rating,
         stock: stockQuantity,
         tags: tags ?? [],
         brand: brand,
         warrantyInformation: 'Standard warranty',
         shippingInformation: 'Standard shipping',
         availabilityStatus: isActive ? 'In Stock' : 'Out of Stock',
         reviews: [],
         returnPolicy: 'Standard return policy',
         createdAt: createdAt,
         images: images,
         thumbnail: images.isNotEmpty ? images.first : '',
       );

  // Factory constructor to create ProductModel from Firestore document
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ProductModel(
      firebaseId: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      salePrice: data['salePrice']?.toDouble(),
      category: data['category'] ?? '',
      brand: data['brand'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      stockQuantity: data['stockQuantity'] ?? 0,
      isActive: data['isActive'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      vendorId: data['vendorId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      specifications: data['specifications'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      sku: data['sku'],
      weight: data['weight']?.toDouble(),
      weightUnit: data['weightUnit'],
      colors: data['colors'] != null ? List<String>.from(data['colors']) : null,
      sizes: data['sizes'] != null ? List<String>.from(data['sizes']) : null,
    );
  }

  // Factory constructor to create ProductModel from JSON (for API compatibility)
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      firebaseId: json['id']?.toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      salePrice: json['salePrice']?.toDouble(),
      category: json['category'] ?? '',
      brand: json['brand'] ?? '',
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      stockQuantity: json['stockQuantity'] ?? 0,
      isActive: json['isActive'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      vendorId: json['vendorId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
      specifications: json['specifications'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      sku: json['sku'],
      weight: json['weight']?.toDouble(),
      weightUnit: json['weightUnit'],
      colors: json['colors'] != null ? List<String>.from(json['colors']) : null,
      sizes: json['sizes'] != null ? List<String>.from(json['sizes']) : null,
    );
  }

  // Convert ProductModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'salePrice': salePrice,
      'category': category,
      'brand': brand,
      'images': images,
      'stockQuantity': stockQuantity,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'rating': rating,
      'reviewCount': reviewCount,
      'vendorId': vendorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'specifications': specifications,
      'tags': tags,
      'sku': sku,
      'weight': weight,
      'weightUnit': weightUnit,
      'colors': colors,
      'sizes': sizes,
    };
  }

  // Create a copy of ProductModel with updated fields
  ProductModel copyWith({
    String? firebaseId,
    String? name,
    String? description,
    double? price,
    double? salePrice,
    String? category,
    String? brand,
    List<String>? images,
    int? stockQuantity,
    bool? isActive,
    bool? isFeatured,
    double? rating,
    int? reviewCount,
    String? vendorId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? specifications,
    List<String>? tags,
    String? sku,
    double? weight,
    String? weightUnit,
    List<String>? colors,
    List<String>? sizes,
  }) {
    return ProductModel(
      firebaseId: firebaseId ?? this.firebaseId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      salePrice: salePrice ?? this.salePrice,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      images: images ?? this.images,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      vendorId: vendorId ?? this.vendorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      specifications: specifications ?? this.specifications,
      tags: tags ?? this.tags,
      sku: sku ?? this.sku,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      colors: colors ?? this.colors,
      sizes: sizes ?? this.sizes,
    );
  }

  // Check if product is on sale
  bool get isOnSale => salePrice != null && salePrice! < price;

  // Get the current price (sale price if available, otherwise regular price)
  double get currentPrice => isOnSale ? salePrice! : price;

  // Calculate discount percentage
  @override
  double get discountPercentage {
    if (!isOnSale) return 0.0;
    return ((price - salePrice!) / price * 100).roundToDouble();
  }

  // Check if product is in stock
  bool get isInStock => stockQuantity > 0;

  // Check if product is low in stock (less than 10 items)
  bool get isLowStock => stockQuantity > 0 && stockQuantity < 10;

  @override
  String toString() {
    return 'ProductModel(id: $firebaseId, name: $name, price: $price, category: $category, brand: $brand)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel && other.firebaseId == firebaseId;
  }

  @override
  int get hashCode => firebaseId.hashCode;
}
