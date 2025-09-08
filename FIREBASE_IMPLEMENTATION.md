# Firebase Implementation Guide for UTM Mart

## Overview
UTM Mart is a multi-vendor e-commerce Flutter application that uses Firebase as its backend service. This document outlines the complete Firebase implementation including setup, services, and data models for supporting multiple vendors where any registered user can buy and sell products.

## Firebase Services Used

### 1. Firebase Core
- **Purpose**: Base Firebase initialization and configuration
- **Configuration**: `lib/firebase_options.dart`
- **Project ID**: `utmmart-13927`

### 2. Firebase Authentication
- **Purpose**: User authentication (login, signup, password reset)
- **Features**: Email/password authentication, Google Sign-In
- **Implementation**: `lib/core/services/firebase_service.dart`

### 3. Cloud Firestore
- **Purpose**: NoSQL database for storing app data
- **Collections**: 
  - `users` - User profiles and preferences
  - `vendors` - Vendor business profiles and information
  - `products` - Product catalog (multi-vendor)
  - `orders` - Customer orders (with vendor information)
  - `categories` - Product categories (global)

### 4. Firebase Storage
- **Purpose**: Store product images and media files
- **Structure**: `products/{productId}/{timestamp}.jpg`

### 5. Firebase Cloud Messaging (FCM)
- **Purpose**: Push notifications for order updates
- **Features**: Background and foreground message handling

### 6. Firebase Analytics
- **Purpose**: Track user behavior and app performance
- **Events**: Product views, order placements, user actions

## Data Models

### Product Model
```dart
class ProductModel {
  final String? id;
  final String name;
  final String description;
  final double price;
  final double? salePrice;
  final String category;
  final String brand;
  final List<String> images;
  final int stockQuantity;
  final bool isActive;
  final bool isFeatured;
  final double rating;
  final int reviewCount;
  final String vendorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  // ... additional fields
}
```

### Order Model
```dart
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
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final String vendorId;
  // ... additional fields
}
```

### Category Model
```dart
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
  // ... additional fields
}
```

## Firebase Service Implementation

### Core Service (`lib/core/services/firebase_service.dart`)
The `FirebaseService` class provides a centralized interface for all Firebase operations:

- **Authentication Methods**: Sign in, sign up, sign out, password reset
- **Product Management**: CRUD operations for products
- **Order Management**: Create, update, and retrieve orders
- **Category Management**: CRUD operations for categories
- **Image Upload**: Product image storage and management
- **Analytics**: Event logging and tracking

### Repository Implementation (`lib/features/shop/data/repository_impl/shop_firebase_repository_impl.dart`)
Implements the `ShopRepo` interface using Firebase:

- **Stream-based Data**: Real-time updates using Firestore streams
- **Vendor Isolation**: All queries filter by `vendorId` for single-vendor setup
- **Error Handling**: Comprehensive error handling and logging
- **Performance**: Optimized queries with proper indexing

## Security Rules

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Vendor profiles - users can create/update their own vendor profile
    match /vendors/{vendorId} {
      allow read: if true; // Public read access for vendor profiles
      allow write: if request.auth != null && 
                   request.auth.uid == vendorId;
    }
    
    // Products - multi-vendor support
    match /products/{productId} {
      allow read: if true; // Public read access
      allow create: if request.auth != null; // Any authenticated user can create products
      allow update, delete: if request.auth != null && 
                            resource.data.vendorId == request.auth.uid;
    }
    
    // Orders - customers can read their own orders, vendors can read orders containing their products
    match /orders/{orderId} {
      allow read: if request.auth != null && 
                  (resource.data.customerId == request.auth.uid ||
                   resource.data.vendorId == request.auth.uid);
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
                    (resource.data.customerId == request.auth.uid ||
                     resource.data.vendorId == request.auth.uid);
    }
    
    // Categories are global - readable by all, writable by admins only
    match /categories/{categoryId} {
      allow read: if true; // Public read access
      allow write: if request.auth != null; // For now, any authenticated user can manage categories
    }
  }
}
```

### Storage Security Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Product images are vendor-specific
    match /products/{vendorId}/{productId}/{fileName} {
      allow read: if true; // Public read access
      allow write: if request.auth != null && 
                   request.auth.uid == vendorId;
    }
    
    // Vendor profile images
    match /vendors/{vendorId}/{fileName} {
      allow read: if true; // Public read access
      allow write: if request.auth != null && 
                   request.auth.uid == vendorId;
    }
  }
}
```

## Admin Dashboard

### Features
- **Product Management**: Add, edit, delete products
- **Order Management**: View and update order statuses
- **Category Management**: Organize products by categories
- **Analytics**: Basic sales and performance metrics

### Implementation
Located at `lib/features/shop/presentation/views/admin_dashboard_view.dart`

## Setup Instructions

### 1. Firebase Project Setup
1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable the required services:
   - Authentication
   - Firestore Database
   - Storage
   - Cloud Messaging
   - Analytics

### 2. FlutterFire CLI Setup
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your Flutter app
flutterfire configure --project=utmmart-13927
```

### 3. Dependencies
Add these to your `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^3.15.1
  firebase_auth: ^5.6.2
  cloud_firestore: ^5.6.2
  firebase_storage: ^12.4.9
  firebase_messaging: ^15.1.3
  firebase_analytics: ^11.3.3
```

### 4. Platform Configuration
- **Android**: `android/app/google-services.json`
- **iOS**: `ios/Runner/GoogleService-Info.plist`
- **Web**: Firebase configuration in `web/index.html`

## Usage Examples

### Adding a Product
```dart
final product = ProductModel(
  name: 'Sample Product',
  description: 'Product description',
  price: 29.99,
  category: 'electronics',
  brand: 'Sample Brand',
  images: ['https://example.com/image.jpg'],
  stockQuantity: 100,
  vendorId: currentUser.uid,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await shopRepo.addProduct(product);
```

### Getting Products Stream
```dart
StreamBuilder<List<ProductModel>>(
  stream: shopRepo.getProducts(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final products = snapshot.data!;
      return ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ProductCard(product: products[index]);
        },
      );
    }
    return CircularProgressIndicator();
  },
);
```

### Updating Order Status
```dart
await shopRepo.updateOrderStatus(
  orderId, 
  OrderStatus.shipped
);
```

## Best Practices

### 1. Data Structure
- Use consistent field naming conventions
- Implement proper indexing for frequently queried fields
- Keep documents small and focused

### 2. Security
- Always validate user authentication
- Implement proper security rules
- Use vendor-specific data isolation

### 3. Performance
- Use streams for real-time updates
- Implement pagination for large datasets
- Cache frequently accessed data

### 4. Error Handling
- Implement comprehensive error handling
- Provide user-friendly error messages
- Log errors for debugging

## Troubleshooting

### Common Issues
1. **Firebase not initialized**: Ensure `Firebase.initializeApp()` is called before using any Firebase services
2. **Permission denied**: Check Firestore security rules and user authentication
3. **Image upload fails**: Verify Storage security rules and file size limits
4. **Real-time updates not working**: Check Firestore stream implementation and network connectivity

### Debug Tips
- Enable Firebase debug logging
- Check Firebase Console for error logs
- Verify security rules in Firebase Console
- Test queries in Firestore console

## Future Enhancements

### Planned Features
- **Advanced Analytics**: Customer behavior tracking, sales reports
- **Inventory Management**: Low stock alerts, automatic reordering
- **Customer Management**: Customer profiles, purchase history
- **Marketing Tools**: Promotional campaigns, email marketing
- **Multi-vendor Support**: Extend to support multiple vendors

### Performance Optimizations
- **Caching Strategy**: Implement local caching for offline support
- **Image Optimization**: Compress and resize images automatically
- **Query Optimization**: Implement advanced indexing strategies
- **Background Sync**: Sync data when app is in background

## Support

For Firebase-related issues:
1. Check [Firebase Documentation](https://firebase.google.com/docs)
2. Review [FlutterFire Documentation](https://firebase.flutter.dev/)
3. Check Firebase Console for service status
4. Review app logs for detailed error information

---

**Note**: This implementation is designed for a multi-vendor e-commerce marketplace where any registered user can buy and sell products. Each user can create their own vendor profile and list products for sale while also being able to purchase from other vendors.

