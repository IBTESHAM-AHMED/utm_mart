import 'package:dartz/dartz.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/usecase/usecase.dart';
import 'package:utmmart/features/auth/data/models/register_req_body.dart';
import 'package:utmmart/features/auth/data/models/register_response.dart';
import 'package:utmmart/features/auth/domain/repository/auth_repo.dart';

class RegisterUsecase extends UseCase<Either, RegisterParams> {
  @override
  Future<Either<String, RegisterUserData>> call({RegisterParams? param}) async {
    if (param == null) throw ArgumentError('RegisterParams cannot be null');

    return await sl<AuthRepo>()
        .register(registerReqBody: param.registerReqBody);
  }
}

class RegisterParams {
  final RegisterReqBody registerReqBody;

  RegisterParams({required this.registerReqBody});
}
