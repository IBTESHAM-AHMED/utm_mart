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
    );
  }
}

class FirebaseRegisterParams {
  final String email;
  final String password;

  FirebaseRegisterParams({required this.email, required this.password});
}
