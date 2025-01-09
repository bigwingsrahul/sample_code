import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:techtruckers/config/theme/app_text_styles.dart';

class CustomOutlineButton extends StatelessWidget {
  const CustomOutlineButton({super.key, required this.text, this.borderColor, required this.onTapEvent});
  final String text;
  final Color? borderColor;
  final VoidCallback onTapEvent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6.h,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor ?? Colors.white)),
      child: Center(
        child: FittedBox(
          child: Text(
            text,
            style: AppTextStyles.textBodyNormal.copyWith(color: Colors.black),
          ),
        ),
      ),
    ).onTap(onTapEvent);
  }
}
