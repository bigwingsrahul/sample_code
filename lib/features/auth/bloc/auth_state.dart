part of 'auth_bloc.dart';

@immutable
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

final class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {

  const AuthLoading();

  @override
  List<Object> get props => [];
}

class AuthFailure extends AuthState {
  final String mError;

  const AuthFailure({required this.mError});

  @override
  List<Object> get props => [mError];
}

class LoginResponseState extends AuthState {
  final LoginResponse data;
  final bool updateToken;
  const LoginResponseState(this.data, this.updateToken);

  @override
  List<Object> get props => [];
}