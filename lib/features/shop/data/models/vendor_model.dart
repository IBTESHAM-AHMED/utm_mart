import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// Simplified seller model - just user details for selling
class SellerModel extends Equatable {
  final String userId; // References the user ID from auth
  final String userName;
  final String userEmail;
  final String userPhone;
  final String userAddress;
  final bool isActive;
  final double rating;
  final int reviewCount;
  final int totalProducts;
  final int totalOrders;
  final double totalRevenue;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SellerModel({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.userAddress,
    this.isActive = true,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.totalProducts = 0,
    this.totalOrders = 0,
    this.totalRevenue = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    userId,
    userName,
    userEmail,
    userPhone,
    userAddress,
    isActive,
    rating,
    reviewCount,
    totalProducts,
    totalOrders,
    totalRevenue,
    createdAt,
    updatedAt,
  ];

  // Factory constructor to create SellerModel from Firestore document
  factory SellerModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return SellerModel(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userPhone: data['userPhone'] ?? '',
      userAddress: data['userAddress'] ?? '',
      isActive: data['isActive'] ?? true,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      totalProducts: data['totalProducts'] ?? 0,
      totalOrders: data['totalOrders'] ?? 0,
      totalRevenue: (data['totalRevenue'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert SellerModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'userAddress': userAddress,
      'isActive': isActive,
      'rating': rating,
      'reviewCount': reviewCount,
      'totalProducts': totalProducts,
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy of SellerModel with updated fields
  SellerModel copyWith({
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? userAddress,
    bool? isActive,
    double? rating,
    int? reviewCount,
    int? totalProducts,
    int? totalOrders,
    double? totalRevenue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SellerModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      userAddress: userAddress ?? this.userAddress,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      totalProducts: totalProducts ?? this.totalProducts,
      totalOrders: totalOrders ?? this.totalOrders,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if seller has complete profile
  bool get hasCompleteProfile {
    return userName.isNotEmpty &&
        userEmail.isNotEmpty &&
        userPhone.isNotEmpty &&
        userAddress.isNotEmpty;
  }

  // Get seller display name
  String get displayName => userName.isNotEmpty ? userName : 'User $userId';

  // Check if seller can sell (active and has complete profile)
  bool get canSell => isActive && hasCompleteProfile;

  @override
  String toString() {
    return 'SellerModel(userId: $userId, userName: $userName, isActive: $isActive)';
  }
}
