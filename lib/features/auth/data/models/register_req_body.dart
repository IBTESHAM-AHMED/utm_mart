import 'package:equatable/equatable.dart';

class RegisterReqBody extends Equatable {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String confirmPassword; // Added confirm password
  final String address;
  final String mobile; // Changed from phone to mobile

  const RegisterReqBody({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.confirmPassword, // Added confirm password
    required this.address,
    required this.mobile, // Added mobile
  });

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'password': password,
    'c_password': confirmPassword, // Include confirm password
    'address': address,
    'mobile': mobile, // Include mobile
  };

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    email,
    password,
    confirmPassword,
    address,
    mobile,
  ]; // Updated props
}
