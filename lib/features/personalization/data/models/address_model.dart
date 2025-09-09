import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String? id;
  final String userUid;
  final List<String> addresses;
  final int defaultIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  AddressModel({
    this.id,
    required this.userUid,
    required this.addresses,
    this.defaultIndex = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert from Firestore document
  factory AddressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AddressModel(
      id: doc.id,
      userUid: data['userUid'] ?? '',
      addresses: List<String>.from(data['addresses'] ?? []),
      defaultIndex: data['defaultIndex'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userUid': userUid,
      'addresses': addresses,
      'defaultIndex': defaultIndex,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Get the default address
  String? get defaultAddress {
    if (addresses.isEmpty) return null;
    if (defaultIndex >= 0 && defaultIndex < addresses.length) {
      return addresses[defaultIndex];
    }
    return addresses.first;
  }

  // Create a copy with updated fields
  AddressModel copyWith({
    String? id,
    String? userUid,
    List<String>? addresses,
    int? defaultIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userUid: userUid ?? this.userUid,
      addresses: addresses ?? this.addresses,
      defaultIndex: defaultIndex ?? this.defaultIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AddressModel(id: $id, userUid: $userUid, addresses: $addresses, defaultIndex: $defaultIndex, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AddressModel &&
        other.id == id &&
        other.userUid == userUid &&
        other.addresses.toString() == addresses.toString() &&
        other.defaultIndex == defaultIndex &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userUid.hashCode ^
        addresses.hashCode ^
        defaultIndex.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
