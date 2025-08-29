import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String? id;
  final String name;
  final String description;
  final String imageUrl;
  final String iconPath;
  final bool isActive;
  final int productCount;
  final String vendorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? tags;
  final String? parentCategoryId;
  final int sortOrder;

  CategoryModel({
    this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.iconPath,
    this.isActive = true,
    this.productCount = 0,
    required this.vendorId,
    required this.createdAt,
    required this.updatedAt,
    this.tags,
    this.parentCategoryId,
    this.sortOrder = 0,
  });

  // Factory constructor to create CategoryModel from Firestore document
  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      iconPath: data['iconPath'] ?? '',
      isActive: data['isActive'] ?? true,
      productCount: data['productCount'] ?? 0,
      vendorId: data['vendorId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      parentCategoryId: data['parentCategoryId'],
      sortOrder: data['sortOrder'] ?? 0,
    );
  }

  // Convert CategoryModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'iconPath': iconPath,
      'isActive': isActive,
      'productCount': productCount,
      'vendorId': vendorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
      'parentCategoryId': parentCategoryId,
      'sortOrder': sortOrder,
    };
  }

  // Create a copy of CategoryModel with updated fields
  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? iconPath,
    bool? isActive,
    int? productCount,
    String? vendorId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    String? parentCategoryId,
    int? sortOrder,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      iconPath: iconPath ?? this.iconPath,
      isActive: isActive ?? this.isActive,
      productCount: productCount ?? this.productCount,
      vendorId: vendorId ?? this.vendorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  // Check if category is a parent category
  bool get isParentCategory => parentCategoryId == null;

  // Check if category is a subcategory
  bool get isSubCategory => parentCategoryId != null;

  // Get display name with product count
  String get displayNameWithCount {
    if (productCount > 0) {
      return '$name ($productCount)';
    }
    return name;
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, productCount: $productCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

