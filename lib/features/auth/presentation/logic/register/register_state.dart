import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:utmmart/core/enums/status.dart';

class RegisterState extends Equatable {
  final RegisterStatus status;
  final String message;
  final User? user;

  const RegisterState({
    this.status = RegisterStatus.initial,
    this.message = '',
    this.user,
  });

  RegisterState copyWith({
    RegisterStatus? status,
    String? message,
    User? user,
  }) {
    return RegisterState(
      status: status ?? this.status,
      message: message ?? this.message,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [status, message, user];
}
