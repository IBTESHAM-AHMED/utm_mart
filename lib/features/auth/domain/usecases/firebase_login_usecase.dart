import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/usecase/usecase.dart';
import 'package:utmmart/features/auth/data/data_sources/firebase_auth_service.dart';
import 'package:utmmart/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:utmmart/features/auth/data/models/login_response.dart';

class FirebaseLoginUsecase
    extends UseCase<Either<String, User>, FirebaseLoginParams> {
  @override
  Future<Either<String, User>> call({FirebaseLoginParams? param}) async {
    if (param == null)
      throw ArgumentError('FirebaseLoginParams cannot be null');

    final result = await sl<FirebaseAuthService>().signInWithEmailAndPassword(
      email: param.email,
      password: param.password,
    );

    // If login succeeded, create and cache a minimal LoginUserData so
    // the rest of the app (which relies on cached API user data) treats
    // the user as logged in. We swallow caching errors to avoid
    // breaking the login flow.
    return await result.fold((l) async => Left(l), (user) async {
      try {
        final loginUser = LoginUserData(
          id: user.uid.hashCode,
          name: user.displayName ?? user.email ?? 'User',
          mobile: '',
          email: user.email ?? '',
          roleId: 1,
          address: '',
          profilePhotoPath: null,
          token: '',
          profilePhotoUrl: user.photoURL ?? '',
        );

        await sl<AuthLocalDataSource>().cacheUserData(loginUser);
      } catch (e) {
        // ignore caching errors; login itself succeeded
      }

      return Right(user);
    });
  }
}

class FirebaseLoginParams {
  final String email;
  final String password;

  FirebaseLoginParams({required this.email, required this.password});
}
