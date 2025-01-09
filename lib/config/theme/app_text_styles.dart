import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class AppTextStyles {

  static TextStyle textSmallNormal = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.normal,
  );

  static TextStyle textSmallSemiBold = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
  );

  static TextStyle textSmallBold = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w700,
  );

  static TextStyle textBodyNormal = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.normal,
  );

  static TextStyle textBodySemiBold = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
  );

  static TextStyle textBodyBold = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w700,
  );

  static TextStyle textTitleNormal = TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.normal,
  );

  static TextStyle textTitleSemiBold = TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.w500,
  );

  static TextStyle textTitleBold = TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.w700,
  );

  static TextStyle textSmallTitleNormal = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.normal,
  );

  static TextStyle textSmallTitleSemiBold = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.w500,
  );

  static TextStyle textSmallTitleBold = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.w700,
  );

  static TextStyle buttonTextStyle = TextStyle(
    fontSize: 16.sp,
      fontWeight: FontWeight.w700,
    color: Colors.white
  );

  static TextStyle custom(double fontSize, FontWeight fontWeight, Color? textColor) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: textColor,
  );

}