import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/enums/status.dart';
import 'package:utmmart/features/auth/domain/usecases/register_usecase.dart';
import 'package:utmmart/features/auth/presentation/logic/register/register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit() : super(const RegisterState());

  Future<void> register(RegisterParams params) async {
    emit(state.copyWith(status: RegisterStatus.loading));

    final result = await sl<RegisterUsecase>().call(param: params);

    result.fold(
          (error) {
        emit(state.copyWith(
          status: RegisterStatus.failure,
          message: error.toString(), // Handle error appropriately
        ));
      },
          (success) {
        emit(state.copyWith(
          status: RegisterStatus.success,
          message: "Your account has been created successfully", // English
        ));
      },
    );
  }
}
