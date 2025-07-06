import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/usecase/usecase.dart';
 import 'package:utmmart/features/auth/data/models/login_response.dart';
import 'package:utmmart/features/auth/domain/repository/auth_repo.dart';

class GetCachedUserUsecase extends UseCase<LoginUserData?, NoParams> {
  @override
  Future<LoginUserData?> call({NoParams? param}) async {
    return await sl<AuthRepo>().getCachedUser();
  }
}
