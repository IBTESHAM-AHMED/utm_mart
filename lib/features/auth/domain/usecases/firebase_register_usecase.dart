import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/usecase/usecase.dart';
import 'package:utmmart/features/auth/data/data_sources/firebase_auth_service.dart';

class FirebaseRegisterUsecase
    extends UseCase<Either<String, User>, FirebaseRegisterParams> {
  @override
  Future<Either<String, User>> call({FirebaseRegisterParams? param}) async {
    if (param == null)
      throw ArgumentError('FirebaseRegisterParams cannot be null');

    return await sl<FirebaseAuthService>().registerWithEmailAndPassword(
      email: param.email,
      password: param.password,
      firstName: param.firstName,
      lastName: param.lastName,
      phoneNumber: param.phoneNumber,
      address: param.address,
    );
  }
}

class FirebaseRegisterParams {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String address;

  FirebaseRegisterParams({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.address,
  });
}
