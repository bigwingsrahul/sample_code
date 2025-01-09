import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:techtruckers/config/helpers/url_helper.dart';
import 'package:techtruckers/config/services/api_service.dart';
import 'package:techtruckers/features/dispatch/models/dispatch_load_data_model.dart';
import 'package:techtruckers/features/dispatch/models/rejection_request_model.dart';

part 'dispatcher_event.dart';
part 'dispatcher_state.dart';

class DispatcherBloc extends Bloc<DispatcherEvent, DispatcherState> {
  DispatcherBloc() : super(DispatcherInitial()) {
    on<NewDispatcherLoadEvent>(_onNewDispatcher);
    on<UpcomingDispatcherLoadEvent>(_onUpcomingDispatcher);
  }

  void _onNewDispatcher(NewDispatcherLoadEvent event, Emitter<DispatcherState> emit) async {
    try {

      if(event.emitLoader) {
        emit(DispatcherLoading());
      }

      var response = await ApiService.instance.get(
          "${UrlHelper.newDispatch}&date=${DateFormat("yyyy-MM-dd").format(DateTime.now())}",
          true);

      if (response.statusCode == 200) {
        var resModel = dispatchLoadDataModelFromJson(response.body);
        emit(DispatcherResponseState(resModel));
      } else if (response.statusCode == 400) {
        Map<String, dynamic> jsonRes = jsonDecode(response.body);
        if (jsonRes.containsKey("error")) {
          emit(DispatcherFailure(mError: jsonRes["error"]));
        } else {
          emit(DispatcherFailure(mError: jsonRes["message"]));
        }
      } else if (response.statusCode == 401) {
        emit(AutoLogoutFailure());
      } else {
        emit(DispatcherFailure(mError: "Technical issue found, Please try again later"));
      }
    } on SocketException {
      emit(const DispatcherFailure(
          mError: "Please check your internet connection"));
    } on ClientException {
      emit(const DispatcherFailure(
          mError: "Please check your internet connection"));
    } catch (e, stack) {
      debugPrint(e.toString());
      log(stack.toString());
      debugPrintStack(stackTrace: stack);
      if (kDebugMode) {
        emit(DispatcherFailure(mError: e.toString()));
      }
    }
  }

  void _onUpcomingDispatcher(UpcomingDispatcherLoadEvent event, Emitter<DispatcherState> emit,) async {
    try {
      emit(DispatcherLoading());

      var response = await ApiService.instance.get(
          "${UrlHelper.upcomingDispatch}&date=${DateFormat("yyyy-MM-dd").format(DateTime.now())}",
          true);

      if (response.statusCode == 200) {
        var resModel = dispatchLoadDataModelFromJson(response.body);
        emit(UpcomingDispatcherResponseState(resModel, event.showJobDone ?? false));
      } else if (response.statusCode == 400) {
        Map<String, dynamic> jsonRes = jsonDecode(response.body);
        if (jsonRes.containsKey("error")) {
          emit(DispatcherFailure(mError: jsonRes["error"]));
        } else {
          emit(DispatcherFailure(mError: jsonRes["message"]));
        }
      } else if (response.statusCode == 401) {
        emit(AutoLogoutFailure());
      } else {
        emit(DispatcherFailure(
            mError: "Technical issue found, Please try again later"));
      }
    } on SocketException {
      emit(const DispatcherFailure(
          mError: "Please check your internet connection"));
    } on ClientException {
      emit(const DispatcherFailure(
          mError: "Please check your internet connection"));
    } catch (e, stack) {
      log(e.toString());
      log(stack.toString());
      debugPrintStack(stackTrace: stack);
      emit(DispatcherFailure(mError: e.toString()));
    }
  }

  Future<XFile?> compressAndGetFile(XFile file, String targetPath) async {
    var result = await FlutterImageCompress.compressAndGetFile(
      file.path, targetPath,
      quality: 88,
    );

    return result;
  }

}
