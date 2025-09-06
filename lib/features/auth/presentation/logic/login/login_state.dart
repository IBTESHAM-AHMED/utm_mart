import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:utmmart/core/enums/status.dart';

class LoginState extends Equatable {
  final LoginStatus status;
  final String message;
  final User? user;

  const LoginState({
    this.status = LoginStatus.initial,
    this.message = '',
    this.user,
  });

  LoginState copyWith({LoginStatus? status, String? message, User? user}) {
    return LoginState(
      status: status ?? this.status,
      message: message ?? this.message,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [status, message, user];
}

//aasdasdasdasda
//aasdasdasdasda
//aasdasdasdasda
//aasdasdasdasda
//aasdasdasdasda
