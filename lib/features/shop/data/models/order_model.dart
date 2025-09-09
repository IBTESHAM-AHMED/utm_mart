import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
  returned,
  refunded,
}

enum PaymentStatus { pending, paid, failed, refunded, partiallyRefunded }

enum PaymentMethod {
  cashOnDelivery,
  creditCard,
  debitCard,
  bankTransfer,
  digitalWallet,
  paypal,
}

class OrderModel {
  final String? id;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final List<OrderItemModel> items;
  final double subtotal;
  final double tax;
  final double shippingCost;
  final double total;
  final String currency;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final String? trackingNumber;
  final String? notes;
  final String vendorId; // Seller's user ID
  final String? vendorName; // Seller's name for buyer reference
  final String? vendorEmail; // Seller's email for buyer reference
  final String? vendorPhone; // Seller's phone for buyer reference
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? estimatedDelivery;
  // TODO: Address fields will be added when we implement order functionality
  // final AddressModel shippingAddress;
  // final AddressModel? billingAddress;

  OrderModel({
    this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.shippingCost,
    required this.total,
    this.currency = 'USD',
    this.status = OrderStatus.pending,
    this.paymentStatus = PaymentStatus.pending,
    required this.paymentMethod,
    this.trackingNumber,
    this.notes,
    required this.vendorId,
    this.vendorName,
    this.vendorEmail,
    this.vendorPhone,
    required this.createdAt,
    required this.updatedAt,
    this.estimatedDelivery,
    // TODO: Address parameters will be added when we implement order functionality
    // required this.shippingAddress,
    // this.billingAddress,
  });

  // Factory constructor to create OrderModel from Firestore document
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data =
        (doc.data() as Map<String, dynamic>?) ?? {};

    DateTime parseToDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    List<OrderItemModel> parseItems(dynamic raw) {
      if (raw == null) return <OrderItemModel>[];
      if (raw is List) {
        return raw
            .where((e) => e != null)
            .map<OrderItemModel>(
              (e) =>
                  OrderItemModel.fromMap(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      }
      return <OrderItemModel>[];
    }

    OrderStatus parseOrderStatus(String? v) {
      if (v == null) return OrderStatus.pending;
      return OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == v,
        orElse: () => OrderStatus.pending,
      );
    }

    PaymentStatus parsePaymentStatus(String? v) {
      if (v == null) return PaymentStatus.pending;
      return PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == v,
        orElse: () => PaymentStatus.pending,
      );
    }

    PaymentMethod parsePaymentMethod(String? v) {
      if (v == null) return PaymentMethod.cashOnDelivery;
      return PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == v,
        orElse: () => PaymentMethod.cashOnDelivery,
      );
    }

    return OrderModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      items: parseItems(data['items']),
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      tax: (data['tax'] ?? 0.0).toDouble(),
      shippingCost: (data['shippingCost'] ?? 0.0).toDouble(),
      total: (data['total'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'USD',
      status: parseOrderStatus(data['status'] as String?),
      paymentStatus: parsePaymentStatus(data['paymentStatus'] as String?),
      paymentMethod: parsePaymentMethod(data['paymentMethod'] as String?),
      trackingNumber: data['trackingNumber'],
      notes: data['notes'],
      vendorId: data['vendorId'] ?? '',
      vendorName: data['vendorName'],
      vendorEmail: data['vendorEmail'],
      vendorPhone: data['vendorPhone'],
      createdAt: parseToDateTime(data['createdAt']),
      updatedAt: parseToDateTime(data['updatedAt']),
      estimatedDelivery: data['estimatedDelivery'] != null
          ? parseToDateTime(data['estimatedDelivery'])
          : null,
      // TODO: Address parsing will be added when we implement order functionality
      // shippingAddress: AddressModel.fromMap(data['shippingAddress'] ?? {}),
      // billingAddress: data['billingAddress'] != null
      //     ? AddressModel.fromMap(data['billingAddress'])
      //     : null,
    );
  }

  // Convert OrderModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'shippingCost': shippingCost,
      'total': total,
      'currency': currency,
      'status': status.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'trackingNumber': trackingNumber,
      'notes': notes,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'vendorEmail': vendorEmail,
      'vendorPhone': vendorPhone,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'estimatedDelivery': estimatedDelivery != null
          ? Timestamp.fromDate(estimatedDelivery!)
          : null,
      // TODO: Address serialization will be added when we implement order functionality
      // 'shippingAddress': shippingAddress.toMap(),
      // 'billingAddress': billingAddress?.toMap(),
    };
  }

  // Create a copy of OrderModel with updated fields
  OrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    List<OrderItemModel>? items,
    double? subtotal,
    double? tax,
    double? shippingCost,
    double? total,
    String? currency,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    String? trackingNumber,
    String? notes,
    String? vendorId,
    String? vendorName,
    String? vendorEmail,
    String? vendorPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? estimatedDelivery,
    // TODO: Address parameters will be added when we implement order functionality
    // AddressModel? shippingAddress,
    // AddressModel? billingAddress,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      shippingCost: shippingCost ?? this.shippingCost,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      notes: notes ?? this.notes,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      vendorEmail: vendorEmail ?? this.vendorEmail,
      vendorPhone: vendorPhone ?? this.vendorPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      // TODO: Address assignment will be added when we implement order functionality
      // shippingAddress: shippingAddress ?? this.shippingAddress,
      // billingAddress: billingAddress ?? this.billingAddress,
    );
  }

  // Get order status display text
  String get statusDisplayText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.returned:
        return 'Returned';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  // Get payment status display text
  String get paymentStatusDisplayText {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.partiallyRefunded:
        return 'Partially Refunded';
    }
  }

  // Get payment method display text
  String get paymentMethodDisplayText {
    switch (paymentMethod) {
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.digitalWallet:
        return 'Digital Wallet';
      case PaymentMethod.paypal:
        return 'PayPal';
    }
  }

  // Check if order can be cancelled
  bool get canBeCancelled =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;

  // Check if order can be updated
  bool get canBeUpdated =>
      status != OrderStatus.delivered && status != OrderStatus.cancelled;

  // Get seller display name for buyer reference
  String get sellerDisplayName {
    if (vendorName != null && vendorName!.isNotEmpty) {
      return vendorName!;
    }
    return 'Seller ID: $vendorId';
  }

  // Get seller contact info for buyer reference
  String get sellerContactInfo {
    List<String> contact = [];
    if (vendorEmail != null && vendorEmail!.isNotEmpty) {
      contact.add('Email: ${vendorEmail!}');
    }
    if (vendorPhone != null && vendorPhone!.isNotEmpty) {
      contact.add('Phone: ${vendorPhone!}');
    }
    return contact.join(' • ');
  }

  @override
  String toString() {
    return 'OrderModel(id: $id, customerName: $customerName, total: $total, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderModel && other.id == id;
  }

  @override
  int get hashCode => id?.hashCode ?? 0;
}

class OrderItemModel {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final double total;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.total,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
      total: (map['total'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'total': total,
    };
  }

  @override
  String toString() {
    return 'OrderItemModel(productId: $productId, productName: $productName, quantity: $quantity, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItemModel && other.productId == productId;
  }

  @override
  int get hashCode => productId.hashCode;
}
