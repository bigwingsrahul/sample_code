import 'package:fbroadcast/fbroadcast.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techtruckers/features/dispatch/bloc/dispatcher_bloc.dart';
import 'package:techtruckers/main.dart';
import 'package:techtruckers/utils/constant.dart';
import 'package:techtruckers/utils/general_functions.dart';

class FCMHandler {
  static const MethodChannel _channel = MethodChannel('com.yourapp/fcm');

  static Future<void> initializeFCM() async {
    try {
      // Initialize the platform-specific notifications setup
      await _channel.invokeMethod('initializeFCM');
    } on PlatformException catch (e) {
      print("Error initializing FCM: ${e.message}");
    }
  }

  static void listenForNotifications() {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onMessageReceived') {
        String title = call.arguments['title'];
        String body = call.arguments['body'];
        print("************** Got here **************");

        print(call.arguments);

        switch (call.arguments["type"]) {
          case Constant.driverLimitReaches:
          case Constant.shiftLimitReaches:
          case Constant.shiftLimitExceeded:
          case Constant.takeBreak:
          case Constant.weeklyLimitReaches:
            FBroadcast.instance()
                .broadcast(Constant.violationAlert, value: call.arguments);
            break;
          default:
            break;
        }

        if(navigatorKey.currentState != null) {
          if(call.arguments["type"].toString().toLowerCase() == "new"){
            callBloc(BlocProvider.of<DispatcherBloc>(navigatorKey.currentState!.context).add(UpcomingDispatcherLoadEvent(true)));
          }else if(call.arguments["type"].toString().toLowerCase() == "update" || call.arguments["type"].toString().toLowerCase() == "cancel"){
            FBroadcast.instance()
                .broadcast(Constant.navChanges, value: call.arguments);
            callBloc(BlocProvider.of<DispatcherBloc>(navigatorKey.currentState!.context).add(NewDispatcherLoadEvent(true)));
            callBloc(BlocProvider.of<DispatcherBloc>(navigatorKey.currentState!.context).add(UpcomingDispatcherLoadEvent(false)));
          }else if(call.arguments["type"].toString().toLowerCase() == "upcoming"){
            callBloc(BlocProvider.of<DispatcherBloc>(navigatorKey.currentState!.context).add(UpcomingDispatcherLoadEvent(true)));
          }else{
            FBroadcast.instance().broadcast(Constant.dispatchRejectionStatus, value: call.arguments);
          }
        }
      }
    });
  }
}
