import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:techtruckers/config/helpers/url_helper.dart';
import 'package:techtruckers/config/services/api_service.dart';
import 'package:techtruckers/features/auth/models/login_response_model.dart';


part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
  }

  void _onLogin(LoginEvent event, Emitter<AuthState> emit,) async {
    try {
      emit(AuthLoading());

      var response = await ApiService.instance
          .post(UrlHelper.login, false, body: event.body);

      if (response.statusCode == 200) {
        var loginRes = LoginResponse.fromJson(jsonDecode(response.body));
        emit(LoginResponseState(loginRes, event.updateToken));
      } else if (response.statusCode == 400) {
        Map<String, dynamic> jsonRes = jsonDecode(response.body);
        if (jsonRes.containsKey("error")) {
          emit(AuthFailure(mError: jsonRes["error"]));
        } else {
          emit(AuthFailure(mError: jsonRes["message"]));
        }
      } else if (response.statusCode == 401) {
        emit(AuthFailure(mError: "Session Expired"));
      } else {
        emit(AuthFailure(
            mError: "Technical issue found, Please try again later"));
      }
    } on SocketException {
      print("Socket Exception");
      emit(const AuthFailure(mError: "Please check your internet connection"));
    } on ClientException {
      print("Client Exception");
      emit(const AuthFailure(mError: "Please check your internet connection"));
    } catch (e, stack) {
      log(e.toString());
      log(stack.toString());
      debugPrintStack(stackTrace: stack);
      emit(AuthFailure(mError: e.toString()));
    }
  }

}
