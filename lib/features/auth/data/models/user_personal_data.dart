import 'package:equatable/equatable.dart';

class UserPersonalData extends Equatable {
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String address;
  final String email;

  const UserPersonalData({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.address,
    required this.email,
  });

  String get fullName => '$firstName $lastName';

  factory UserPersonalData.fromJson(Map<String, dynamic> json) {
    return UserPersonalData(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      address: json['address'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'address': address,
      'email': email,
    };
  }

  UserPersonalData copyWith({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? address,
    String? email,
  }) {
    return UserPersonalData(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      email: email ?? this.email,
    );
  }

  @override
  List<Object?> get props => [firstName, lastName, phoneNumber, address, email];
}
