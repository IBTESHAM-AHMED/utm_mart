import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/services/firebase_service.dart';
import 'package:utmmart/features/personalization/data/models/address_model.dart';

class AddressService {
  final FirebaseService _firebaseService = sl<FirebaseService>();

  // Get user's addresses document
  Future<AddressModel?> getUserAddresses(String userUid) async {
    try {
      final querySnapshot = await _firebaseService.firestore
          .collection('addresses')
          .where('userUid', isEqualTo: userUid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return AddressModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user addresses: $e');
    }
  }

  // Get addresses stream for real-time updates
  Stream<AddressModel?> getUserAddressesStream(String userUid) {
    return _firebaseService.firestore
        .collection('addresses')
        .where('userUid', isEqualTo: userUid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return AddressModel.fromFirestore(snapshot.docs.first);
          }
          return null;
        });
  }

  // Add a new address
  Future<void> addAddress(String userUid, String newAddress) async {
    try {
      final existingDoc = await getUserAddresses(userUid);

      if (existingDoc != null) {
        // Update existing document
        final updatedAddresses = [...existingDoc.addresses, newAddress];
        await _firebaseService.firestore
            .collection('addresses')
            .doc(existingDoc.id)
            .update({
              'addresses': updatedAddresses,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      } else {
        // Create new document
        await _firebaseService.firestore.collection('addresses').add({
          'userUid': userUid,
          'addresses': [newAddress],
          'defaultIndex': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to add address: $e');
    }
  }

  // Update an address
  Future<void> updateAddress(
    String userUid,
    int index,
    String newAddress,
  ) async {
    try {
      final existingDoc = await getUserAddresses(userUid);

      if (existingDoc != null && index < existingDoc.addresses.length) {
        final updatedAddresses = List<String>.from(existingDoc.addresses);
        updatedAddresses[index] = newAddress;

        await _firebaseService.firestore
            .collection('addresses')
            .doc(existingDoc.id)
            .update({
              'addresses': updatedAddresses,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      } else {
        throw Exception('Address not found or invalid index');
      }
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  // Delete an address
  Future<void> deleteAddress(String userUid, int index) async {
    try {
      final existingDoc = await getUserAddresses(userUid);

      if (existingDoc != null && index < existingDoc.addresses.length) {
        final updatedAddresses = List<String>.from(existingDoc.addresses);
        updatedAddresses.removeAt(index);

        // Adjust default index if necessary
        int newDefaultIndex = existingDoc.defaultIndex;
        if (index < existingDoc.defaultIndex) {
          newDefaultIndex = existingDoc.defaultIndex - 1;
        } else if (index == existingDoc.defaultIndex) {
          newDefaultIndex = 0; // Set to first address
        }

        // Ensure default index is valid
        if (newDefaultIndex >= updatedAddresses.length &&
            updatedAddresses.isNotEmpty) {
          newDefaultIndex = updatedAddresses.length - 1;
        }

        await _firebaseService.firestore
            .collection('addresses')
            .doc(existingDoc.id)
            .update({
              'addresses': updatedAddresses,
              'defaultIndex': newDefaultIndex,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      } else {
        throw Exception('Address not found or invalid index');
      }
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  // Set default address
  Future<void> setDefaultAddress(String userUid, int index) async {
    try {
      final existingDoc = await getUserAddresses(userUid);

      if (existingDoc != null && index < existingDoc.addresses.length) {
        // Update addresses collection
        await _firebaseService.firestore
            .collection('addresses')
            .doc(existingDoc.id)
            .update({
              'defaultIndex': index,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        // Update users collection with the default address
        await _firebaseService.firestore
            .collection('users')
            .doc(userUid)
            .update({
              'address': existingDoc.addresses[index],
              'updatedAt': FieldValue.serverTimestamp(),
            });
      } else {
        throw Exception('Address not found or invalid index');
      }
    } catch (e) {
      throw Exception('Failed to set default address: $e');
    }
  }

  // Get the default address
  Future<String?> getDefaultAddress(String userUid) async {
    try {
      final addressDoc = await getUserAddresses(userUid);
      return addressDoc?.defaultAddress;
    } catch (e) {
      throw Exception('Failed to get default address: $e');
    }
  }
}
