// ignore_for_file: deprecated_member_use, file_names, empty_catches

import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:getwidget/components/border/gf_border.dart';
import 'package:getwidget/types/gf_border_type.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:techtruckers/config/helpers/preferences_helper.dart';
import 'package:techtruckers/config/theme/app_colors.dart';
import 'package:techtruckers/config/theme/app_text_styles.dart';
import 'package:techtruckers/features/auth/bloc/auth_bloc.dart';
import 'package:techtruckers/features/common/widgets/custom_gradient_button.dart';
import 'package:techtruckers/features/common/widgets/custom_outline_button.dart';
import 'package:techtruckers/features/dashboard/views/homepage.dart';
import 'package:techtruckers/main.dart';
import 'package:techtruckers/utils/constant.dart';
import 'package:techtruckers/utils/general_functions.dart';
import 'package:video_player/video_player.dart';

import '../widgets/textFormFields.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController controllerEmail = TextEditingController();
  TextEditingController controllerPassword = TextEditingController();
  bool showPassword = false;
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  late VideoPlayerController _controller;
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/bg_video.mp4')
      ..setLooping(true)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.sizeOf(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthLoading) {
          setState(() {
            isLoading = true;
          });
        }

        if (state is AuthFailure) {
          setState(() {
            isLoading = false;
          });

          showToast(context, state.mError, true);
        }

        if (state is LoginResponseState) {
          try {
            if (state.data.data == null) {
              showToast(context, (state.data.message ?? "Something went wrong").toString(), true);
              return;
            }

            setState(() {
              isLoading = false;
            });

            if (state.updateToken) {
              await PreferencesHelper.instance.setString(Constant.token, state.data.data?.loginToken ?? "");
              await PreferencesHelper.instance.setInt(Constant.driverId, state.data.data?.id ?? -1);
              await PreferencesHelper.instance.setString(Constant.name, state.data.data?.firstName ?? "");
              await PreferencesHelper.instance.setString(Constant.email, state.data.data?.email ?? "");
              await PreferencesHelper.instance.setString(Constant.profileImage, state.data.data?.profilePic ?? "");
              await PreferencesHelper.instance.setString(Constant.password, controllerPassword.text);
              if (context.mounted) {
                navigateWithNoStack(context, HomePage());
              }
            } else {
              if (state.data.loggedinUser ?? false) {
                showAlreadyLoggedInDialog(state.data.data?.deviceName ?? "");
              } else {
                _onLogin(true);
              }
            }
          } catch (error) {
            print(error.toString());
            if (context.mounted) {
              showToast(context, error.toString(), true);
            }
          }
        }
      },
      child: WillPopScope(
        onWillPop: () async {
          bool confirm = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Confirmation'),
                content: Text('Do you really want to go back?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: Text('No'),
                  ),
                  TextButton(
                    onPressed: () {
                      SystemNavigator.pop();
                    },
                    child: Text('Yes'),
                  ),
                ],
              );
            },
          );
          return confirm;
        },
        child: Scaffold(
          body: Stack(
            children: [
              _controller.value.isInitialized
                  ? VideoPlayer(_controller)
                  : Container(
                      width: size.width,
                      height: size.height,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/loginScreenBackImage.png"),
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
              SingleChildScrollView(
                child: Column(
                  children: [
                    Row(),
                    SizedBox(height: 12.h),
                    Image(
                      image: AssetImage("assets/logo.png"),
                      width: size.width / 2,
                      fit: BoxFit.fill,
                    ),
                    SizedBox(height: 8.h),
                    SizedBox(
                      width: size.width / 1.5,
                      child: Center(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xff0082FB),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(10),
                                ),
                              ),
                              height: size.height * .07,
                              width: 5,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Text("Welcome", style: AppTextStyles.custom(20.sp, FontWeight.bold, Colors.white)),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 4.0),
                                  child: Text("to Tech Truckers", style: AppTextStyles.custom(20.sp, FontWeight.bold, Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                        child: Container(
                          height: size.height * 0.4,
                          width: size.width / 1.1,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.1),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Container(), // Placeholder
                                  Container(), // Placeholder
                                  Text(
                                    "Please enter your Email ID & Password",
                                    style: AppTextStyles.textSmallBold.copyWith(color: Colors.white),
                                  ),
                                  CustomTextEditingWidget(
                                    height: size.height * .05,
                                    width: size.width / 1.4,
                                    autofillHints: [AutofillHints.email],
                                    icon: Icon(
                                      Icons.mail,
                                      color: AppColors.colorPrimary,
                                    ),
                                    validator: (val) {
                                      if (val.isEmptyOrNull) {
                                        return "Please enter email id";
                                      }

                                      if (!val.validateEmail()) {
                                        return "Please enter valid email id";
                                      }

                                      return null;
                                    },
                                    hintText: "Email",
                                    controller: controllerEmail,
                                    obscureText: false,
                                  ),
                                  CustomTextEditingWidget(
                                    height: size.height * .05,
                                    width: size.width / 1.4,
                                    autofillHints: [AutofillHints.password],
                                    icon: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          showPassword = !showPassword;
                                        });
                                      },
                                      child: Icon(
                                        showPassword ? Icons.visibility_off : Icons.remove_red_eye,
                                        color: AppColors.colorPrimary,
                                      ),
                                    ),
                                    validator: (val) {
                                      if (val.isEmptyOrNull) {
                                        return "Please enter password";
                                      }

                                      return null;
                                    },
                                    hintText: "Password",
                                    obscureText: !showPassword,
                                    controller: controllerPassword,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      FocusScope.of(context).unfocus();
                                      _onLogin(false);
                                    },
                                    child: Container(
                                      height: size.height * .05,
                                      width: size.width / 1.4,
                                      decoration: BoxDecoration(
                                        color: AppColors.colorPrimary,
                                        borderRadius: BorderRadius.circular(10000),
                                      ),
                                      child: Center(
                                        child: isLoading
                                            ? SizedBox(
                                                height: size.height * .03,
                                                width: size.height * .03,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                "LOG IN",
                                                style: AppTextStyles.buttonTextStyle,
                                              ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: size.width / 1.5,
                                    child: Center(
                                      child: RichText(
                                        text: TextSpan(
                                          text: "By login, you agree to our ",
                                          style: AppTextStyles.custom(13.sp, FontWeight.normal, Color(0xffC2C0C2)),
                                          children: [
                                            TextSpan(
                                              text: "Terms and Conditions.",
                                              style: AppTextStyles.custom(13.sp, FontWeight.normal, AppColors.colorPrimary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(), // Placeholder
                                  SizedBox(
                                    width: size.width / 4,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: const [
                                        ImageIcon(
                                          AssetImage("assets/fbicon.png"),
                                          size: 24,
                                          color: Colors.white,
                                        ),
                                        ImageIcon(
                                          AssetImage("assets/instaicon.png"),
                                          size: 24,
                                          color: Colors.white,
                                        ),
                                        ImageIcon(
                                          AssetImage("assets/tewittericon.png"),
                                          size: 24,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox.shrink(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onLogin(bool updateToken) async {
    if (controllerEmail.text.trim().isEmptyOrNull) {
      showToast(context, "Please enter email id", true);
      return;
    }

    if (!controllerEmail.text.trim().validateEmail()) {
      showToast(context, "Please enter valid email id", true);
      return;
    }

    if (controllerPassword.text.trim().isEmptyOrNull) {
      showToast(context, "Please enter password", true);
      return;
    }

    var token = await getDeviceToken();
    // var token = "";
    try {
      String deviceName = "";

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceName = androidInfo.model;
      } else {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.name;
      }

      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();

      var loginBody = {
        'email': controllerEmail.text.trim(),
        'password': controllerPassword.text.trim(),
        "updateToken": updateToken,
        "deviceToken": token,
        "timezone": currentTimeZone,
        "deviceType": Platform.isAndroid ? 'android' : 'ios',
        "deviceName": deviceName
      };

      callBloc(BlocProvider.of<AuthBloc>(context).add(LoginEvent(body: loginBody, updateToken: updateToken)));
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  void showAlreadyLoggedInDialog(String device) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: EdgeInsets.all(12),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: GFBorder(
                      strokeWidth: 2,
                      dashedLine: [4, 5],
                      type: GFBorderType.rRect,
                      color: textSecondaryColor,
                      radius: Radius.circular(15),
                      child: Container(
                        width: MediaQuery.sizeOf(context).width / 1.5,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 5,
                            ),
                            Image.asset(
                              "assets/dispatchicon.png",
                              color: AppColors.blackWhiteText(context),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Text(
                              "Already logged in!",
                              style: AppTextStyles.textBodyBold,
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                      text: "This account is currently active on ",
                                      style: AppTextStyles.textSmallNormal.copyWith(color: AppColors.blackWhiteText(context)),
                                      children: [
                                        TextSpan(
                                          text: device,
                                          style: AppTextStyles.textSmallBold.copyWith(color: AppColors.blackWhiteText(context)),
                                        ),
                                        TextSpan(
                                          text: ", Logging it here will logout other device",
                                          style: AppTextStyles.textSmallNormal.copyWith(color: AppColors.blackWhiteText(context)),
                                        ),
                                      ])),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                SizedBox(
                                  height: 4.h,
                                  child: CustomGradientButton(
                                    text: "Accept",
                                    borderColor: AppColors.colorPrimary,
                                    onTapEvent: () {
                                      Navigator.pop(context);
                                      _onLogin(true);
                                    },
                                  ),
                                ).expand(),
                                16.width,
                                SizedBox(
                                  height: 4.h,
                                  child: CustomOutlineButton(
                                    text: "Cancel",
                                    borderColor: Colors.black,
                                    onTapEvent: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ).expand(),
                              ],
                            ),
                            SizedBox(
                              height: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ));
  }
}
