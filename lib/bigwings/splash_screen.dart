import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:techtruckers/config/helpers/preferences_helper.dart';
import 'package:techtruckers/features/auth/views/login_screen.dart';
import 'package:techtruckers/features/dashboard/views/homepage.dart';
import 'package:techtruckers/main.dart';
import 'package:techtruckers/utils/constant.dart';
import 'package:techtruckers/utils/general_functions.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    fetchRemoteConfig();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset("assets/images/bw_logo.jpg"),
      ),
    );
  }

  Future<void> fetchRemoteConfig() async {
    final remoteConfig = FirebaseRemoteConfig.instance;

    try {
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: Duration.zero,
      ));
      await remoteConfig.fetchAndActivate();

      // Get the value with a default value
      geoFenceDistance = remoteConfig.getInt("geoFenceDistance");

        var token = PreferencesHelper.instance.getString(Constant.token, defaultValue: "");

        if (!token.isEmptyOrNull) {
          navigate(context, HomePage(), true);
        } else {
          navigate(context, LoginScreen(), true);
        }
    } catch (e) {
      debugPrint("Error fetching Remote Config: $e");
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      });
    }
  }

}
