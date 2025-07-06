import 'package:equatable/equatable.dart';
import 'package:utmmart/core/enums/status.dart';
import 'package:utmmart/features/auth/data/models/login_response.dart';

class CachedUserState extends Equatable {
  final CachedUserStatus status;
  final LoginUserData? userData;
  final String? errorMessage;

  const CachedUserState({
    this.status = CachedUserStatus.initial,
    this.userData,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, userData, errorMessage];

  CachedUserState copyWith({
    CachedUserStatus? status,
    LoginUserData? userData,
    String? errorMessage,
  }) {
    return CachedUserState(
      status: status ?? this.status,
      userData: userData ?? this.userData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
