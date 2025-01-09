import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:techtruckers/config/theme/app_colors.dart';
import 'package:techtruckers/config/theme/app_text_styles.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final Color? borderColor;
  final Color? color;
  final double? height;
  final double? borderRadius;
  final Color? textColor;
  final TextStyle? appTextStyle;
  final List<Color> gradientColors;
  final VoidCallback onTapEvent;

  const CustomButton(
      {super.key, required this.text, this.borderColor, required this.onTapEvent, this.color, this.gradientColors = const [], this.textColor, this.appTextStyle, this.height, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 6.h,
      decoration: gradientColors.isEmpty
          ? BoxDecoration(
              color: color ?? AppColors.getPrimaryColor(context),
              borderRadius: BorderRadius.circular(borderRadius ?? 12),
              border: Border.all(color: borderColor ?? AppColors.colorPrimary))
          : BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(borderRadius ?? 12),
              border: Border.all(color: borderColor ?? AppColors.colorPrimary)),
      child: Center(
        child: Text(
          text,
          style: appTextStyle ?? AppTextStyles.buttonTextStyle.copyWith(
            color: textColor ?? Colors.white
          ),
        ),
      ),
    ).onTap(onTapEvent);
  }
}
