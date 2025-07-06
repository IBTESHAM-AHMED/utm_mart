import 'package:dartz/dartz.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/usecase/usecase.dart';
import 'package:utmmart/features/auth/data/models/login_req_body.dart';
import 'package:utmmart/features/auth/data/models/login_response.dart';
import 'package:utmmart/features/auth/domain/repository/auth_repo.dart';

class LoginUsecase extends UseCase<Either, LoginParms> {
  @override
  Future<Either<String, LoginUserData>> call({LoginParms? param}) async {
    if (param == null) throw ArgumentError('RegisterParams cannot be null');

    return await sl<AuthRepo>().login(loginReqBody: param.loginReqBody);
  }
}

class LoginParms {
  final LoginReqBody loginReqBody;

  LoginParms({required this.loginReqBody});
}
