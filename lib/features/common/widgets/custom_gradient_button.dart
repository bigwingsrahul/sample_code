import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:techtruckers/config/theme/app_colors.dart';
import 'package:techtruckers/config/theme/app_text_styles.dart';

class CustomGradientButton extends StatelessWidget {
  final String text;
  final Color? borderColor;
  final Widget? child;
  final VoidCallback onTapEvent;

  const CustomGradientButton(
      {super.key, required this.text, this.borderColor, required this.onTapEvent, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6.h,
      decoration: AppColors.isDark(context)
          ? BoxDecoration(
              color: AppColors.colorPrimaryNight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor ?? Colors.transparent))
          : BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xff0082FB), AppColors.colorPrimary]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor ?? AppColors.colorPrimary)),
      child: Center(
        child: child ?? Text(
          text,
          style: AppTextStyles.buttonTextStyle,
        ),
      ),
    ).onTap(onTapEvent);
  }
}
