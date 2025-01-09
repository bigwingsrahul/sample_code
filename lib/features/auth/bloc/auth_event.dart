part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginEvent extends AuthEvent {
  final bool updateToken;
  final Map<String, dynamic> body;

  const LoginEvent({required this.updateToken, required this.body});

  @override
  List<Object> get props => [body, updateToken];
}