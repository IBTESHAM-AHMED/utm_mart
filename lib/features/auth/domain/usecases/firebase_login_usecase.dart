import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/usecase/usecase.dart';
import 'package:utmmart/features/auth/data/data_sources/firebase_auth_service.dart';

class FirebaseLoginUsecase
    extends UseCase<Either<String, User>, FirebaseLoginParams> {
  @override
  Future<Either<String, User>> call({FirebaseLoginParams? param}) async {
    if (param == null)
      throw ArgumentError('FirebaseLoginParams cannot be null');

    return await sl<FirebaseAuthService>().signInWithEmailAndPassword(
      email: param.email,
      password: param.password,
    );
  }
}

class FirebaseLoginParams {
  final String email;
  final String password;

  FirebaseLoginParams({required this.email, required this.password});
}
