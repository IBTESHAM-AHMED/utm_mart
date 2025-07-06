// get_cached_user_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utmmart/core/depandancy_injection/service_locator.dart';
import 'package:utmmart/core/enums/status.dart';
import 'package:utmmart/features/auth/domain/usecases/get_cached_user_usecase.dart';
import 'package:utmmart/features/auth/presentation/logic/get_cached_user/get_cached_user_state.dart';

class CachedUserCubit extends Cubit<CachedUserState> {
  CachedUserCubit() : super(const CachedUserState());

  Future<void> getCachedUser() async {
    emit(state.copyWith(status: CachedUserStatus.loading));

    try {
      final userData = await sl<GetCachedUserUsecase>().call();
      if (userData != null) {
        emit(state.copyWith(
          status: CachedUserStatus.success,
          userData: userData,
        ));
      } else {
        emit(state.copyWith(
          status: CachedUserStatus.failure,
          errorMessage:
          'No cached user data found',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: CachedUserStatus.failure,
        errorMessage:
        'Error fetching user data: $e',
      ));
    }
  }
}
