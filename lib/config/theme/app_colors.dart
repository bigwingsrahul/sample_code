import 'package:flutter/material.dart';

class AppColors {

  static var colorPrimary = Color(0xff01AAE9);
  static var colorPrimaryNight = Color(0xff0082FB);
  static var bottomNavBarBgNight = Color(0xff121212);
  static var darkBackground = Color(0XFF0C0D13);
  static var scaffoldDarkBackground = Color(0XFF363640);
  // static var cardDarkColor = Color(0XFF6A6A7A);
  static var cardDarkColor = Color(0XFF5D5E63);
  static var appRedColor = Color(0XFFFF0266);
  static var appGreenColor = Color(0XFF1EB980);

  // Chart colors
  static var appChartBlue = Color(0XFF72DEFF);
  static var appChartYellow = Color(0XFFFFCF44);
  static var appChartPink = Color(0XFFFF7597);
  static var appChartGreen = Color(0XFF1EB980);
  static var appChartRed = Color(0XFFFF6859);

  static bool isDark(BuildContext context) {
    Brightness brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark;
  }

  static LinearGradient homeBlocksGradient(BuildContext context) {
    return isDark(context)
        ? LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: const [Color(0XFF000000), Color(0XFF000000), Color(0XFF2782F9)],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [Colors.white, Colors.white],
          );
  }

  static LinearGradient homeBackgroundGradient(BuildContext context) {
    return isDark(context)
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: const [Color(0XFF363640), Color(0XFF363640)],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0XFF0082FB),
              colorPrimary,
              Colors.white,
              Colors.white
            ],
          );
  }

  static Color blackWhiteBackground(BuildContext context) {
    return !isDark(context) ? Colors.white : Colors.black;
  }

  static Color colorblueandblackforBottomNavigation(BuildContext context) {
    return isDark(context) ? Colors.black : AppColors.colorPrimary;
  }

  static Color colorblueandwhiteforBottomNavigation(BuildContext context) {
    return !isDark(context) ? Colors.white : AppColors.colorPrimary;
  }

  static Color notcolorblueandwhiteforBottomNavigation(BuildContext context) {
    return isDark(context) ? Colors.white : AppColors.colorPrimary;
  }

  static Color parmanentwhitwcolor(BuildContext context) {
    return Colors.white;
  }

  static Color blackWhiteText(BuildContext context) {
    return isDark(context) ? Colors.white : Colors.black;
  }

  static Color whiteBlacktext(BuildContext context) {
    return !isDark(context) ? Colors.white : Colors.black;
  }

  static Color accentColor(BuildContext context) {
    return Colors.blueAccent;
  }

  static Color appbarBgColor(BuildContext context) {
    return isDark(context) ? Color(0xff121212) : Colors.white ;
  }

  static Color getPrimaryColor(BuildContext context) {
    return isDark(context) ? colorPrimaryNight : colorPrimary ;
  }

  static Color getBorderColor(BuildContext context) {
    return isDark(context) ? Colors.transparent : colorPrimary ;
  }

  static List<Color> getButtonGradient(BuildContext context) {
    return isDark(context) ? [colorPrimaryNight, colorPrimaryNight] : [Color(0xff0082FB), colorPrimary] ;
  }


}
