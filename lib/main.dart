// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';

import 'package:fbroadcast/fbroadcast.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:techtruckers/bigwings/splash_screen.dart';
import 'package:techtruckers/config/helpers/bloc_generator.dart';
import 'package:techtruckers/config/helpers/fcm_handler.dart';
import 'package:techtruckers/config/helpers/preferences_helper.dart';
import 'package:techtruckers/config/helpers/tts_helper.dart';
import 'package:techtruckers/config/services/api_service.dart';
import 'package:techtruckers/config/theme/app_colors.dart';
import 'package:techtruckers/features/dispatch/models/dispatch_load_data_model.dart';
import 'package:techtruckers/firebase_options.dart';
import 'package:techtruckers/utils/constant.dart';
import 'package:techtruckers/utils/general_functions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'bloc/themeCubit.dart';
import 'features/dispatch/bloc/dispatcher_bloc.dart' hide AutoLogoutFailure;
import 'functions/sharedPrefrences.dart';

// Global variables
final navigatorKey = GlobalKey<NavigatorState>();
ValueNotifier<int> newDispatchCount = ValueNotifier(0);
final ValueNotifier<bool> newNotif = ValueNotifier(false);
int semaphore = 0;
int geoFenceDistance = 400;
const platform = MethodChannel('com.yourapp/fcm');
List<DispatchLoadData> activeLoadData = [];
ValueNotifier<GeoCoordinates> currentLocation = ValueNotifier(GeoCoordinates(0.0, 0.0));
final ValueNotifier<bool> showLoader = ValueNotifier(false);


void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await initializeHERESDK();
  // await initializeService();
  if(Platform.isIOS){
    await setForegroundNotificationOptions();
  }

  if(Platform.isAndroid){
    HttpOverrides.global = MyHttpOverrides();
  }

  await PreferencesHelper.init();
  await ApiService.init();
  await TextToSpeechService.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  FCMHandler.listenForNotifications();
  getDeviceToken();

  /*await FirebaseMessaging.instance.requestPermission();
  // await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
  //   alert: true,
  //   badge: true,
  //   sound: true,
  // );
  getDeviceToken();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    if (semaphore != 0) {
      return;
    }

    semaphore = 1;
    Future.delayed(Duration(milliseconds: 1200)).then((_) => semaphore = 0);

    await setup(message);
    print("Notification came");
    showLocalNotification(message.data["title"],
        message.data["body"], "Foreground");
    await TextToSpeechService.speak(message.data["title"] ?? "");
    handleData(message.data);
  });*/

  ThemePreferences preferences = ThemePreferences();
  ThemeModeEnum themeModeEnum = await preferences.getTheme();

  await Permission.notification.request();
  await Permission.phone.request();

  runApp(MyApp(themeModeEnum: themeModeEnum, preferences: preferences));
}

void handleData(Map<String, dynamic> data) {
  if (data.containsKey("type")) {

    if(navigatorKey.currentState != null) {
      if(data["type"].toString().toLowerCase() == "new"){
        callBloc(BlocProvider.of<DispatcherBloc>(navigatorKey.currentState!.context).add(NewDispatcherLoadEvent(true)));
      }else if(data["type"].toString().toLowerCase() == "update" || data["type"].toString().toLowerCase() == "cancel"){
        callBloc(BlocProvider.of<DispatcherBloc>(navigatorKey.currentState!.context).add(NewDispatcherLoadEvent(true)));
        callBloc(BlocProvider.of<DispatcherBloc>(navigatorKey.currentState!.context).add(UpcomingDispatcherLoadEvent(false)));
      }else if(data["type"].toString().toLowerCase() == "upcoming"){
        callBloc(BlocProvider.of<DispatcherBloc>(navigatorKey.currentState!.context).add(UpcomingDispatcherLoadEvent(true)));
      }else{
        FBroadcast.instance().broadcast(Constant.dispatchRejectionStatus, value: data);
      }
    }
  }
}

/*@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await setup(message);
    await TextToSpeechService.initialize();

    if (message.notification != null) {
    showLocalNotification(message.data["title"] ?? "-",
        message.data["body"] ?? "-", "Background");
    await TextToSpeechService.speak(message.data["title"] ?? "");

    }

    handleData(message.data);
  }catch(e, stack){
    print(e.toString());
    print(stack);
  }
}

Future<String> getDeviceToken() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    if (Platform.isIOS) {
      String? apnsToken;
      try {
        apnsToken = await messaging.getAPNSToken();
        if (apnsToken == null) {
          await Future.delayed(const Duration(seconds: 3));
          apnsToken = await messaging.getAPNSToken();
        } else {
        }
      } catch (exception) {}
    }

    String? token = await messaging.getToken();
    print("Device Token is $token");
    return token ?? "";
  } catch (_) {
    return "";
  }
}*/

Future<String> getDeviceToken() async {
  try {

    final String token = await platform.invokeMethod('getToken');
    print("Device Token is $token");
    return token ?? "";
  } catch (_) {
    return "";
  }
}

class MyApp extends StatefulWidget {
  const MyApp(
      {super.key, required this.themeModeEnum, required this.preferences});

  final ThemeModeEnum themeModeEnum;
  final ThemePreferences preferences;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    startLocationService();

    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation
      )
    ).listen((Position position) {
      currentLocation.value = GeoCoordinates(position.latitude, position.longitude);
    });


    FBroadcast.instance().register(Constant.violationAlert, (value, callback) {
      if(navigatorKey.currentState != null){
        // ViolationDialog().show(navigatorKey.currentState!.context, value["title"]);
      }else{
        debugPrint("Current state is null");
      }
    });

  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: BlocGenerator.generateBloc(),
      child: BlocProvider(
        create: (context) =>
            ThemeCubit(widget.themeModeEnum, widget.preferences),
        child: BlocBuilder<ThemeCubit, ThemeModeEnum>(
          builder: (context, themeMode) {
            return ResponsiveSizer(
              builder: (context, orientation, screenType) {
                return MaterialApp(
                  localizationsDelegates: [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: [
                    const Locale('en', ''),
                  ],
                  debugShowCheckedModeBanner: false,
                  navigatorKey: navigatorKey,
                  theme: ThemeData(
                    useMaterial3: false,
                    fontFamily: 'Montserrat',
                    scaffoldBackgroundColor: themeMode == ThemeModeEnum.light
                        ? Colors.white
                        : AppColors.scaffoldDarkBackground,
                    dividerColor:
                        AppColors.blackWhiteText(context).withValues(alpha: 0.8),
                    brightness: themeMode == ThemeModeEnum.light
                        ? Brightness.light
                        : Brightness.dark,
                  ),
                  home: SplashScreen(),
                  // home: HomeScreen(),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> startLocationService() async {
    var locationPerm = await Geolocator.checkPermission();

    if(locationPerm == LocationPermission.always || locationPerm == LocationPermission.whileInUse) {
      if(Platform.isAndroid) {
        await platform.invokeMethod("startLocationService");
      }
    }else{
      await Geolocator.requestPermission();
      startLocationService();
    }
  }
}

Future<void> initializeHERESDK() async {
  SdkContext.init(IsolateOrigin.main);

  // Set your credentials for the HERE SDK.
  String accessKeyId = "AccessKeyID";
  String accessKeySecret = "AccessKeySecret";
  SDKOptions sdkOptions = SDKOptions.withAuthenticationMode(AuthenticationMode.withKeySecret(accessKeyId, accessKeySecret));

  try {
    await SDKNativeEngine.makeSharedInstance(sdkOptions);
  } on InstantiationException {
    throw Exception("Failed to initialize the HERE SDK.");
  }
}

// Set notification presentation options for the foreground
Future<void> setForegroundNotificationOptions() async {
  try {
    await platform.invokeMethod('setForegroundNotificationPresentationOptions', ['banner', 'sound']);
  } on PlatformException catch (e) {
    print("Failed to set foreground notification options: ${e.message}");
  }
}

class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}