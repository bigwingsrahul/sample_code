import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:techtruckers/config/theme/app_colors.dart';
import 'package:techtruckers/config/theme/app_text_styles.dart';

class CustomTabItem extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback? onTapEvent;

  const CustomTabItem(
      {super.key, required this.text, this.onTapEvent, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 5.h,
      decoration: isActive ? BoxDecoration(
          color: AppColors.getPrimaryColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.transparent)) : BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xff707070))),
      child: Center(
        child: Text(
          text,
          style: isActive ? AppTextStyles.buttonTextStyle : AppTextStyles.buttonTextStyle.copyWith(
              color: Colors.black,
            fontWeight: FontWeight.normal
          ),
        ),
      ),
    ).onTap(onTapEvent);
  }
}
