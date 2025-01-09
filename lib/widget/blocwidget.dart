// ignore_for_file: non_ ant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:techtruckers/config/theme/app_colors.dart';
import 'package:techtruckers/config/theme/app_text_styles.dart';

class BlockWidget extends StatelessWidget {
  final double width;
  final String icon;
  final String text;
  final int count;

  const BlockWidget(
      {required this.width,
      super.key,
      required this.icon,
      required this.text,
      required this.count});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: width * 0.5,
      width: width * 0.5,
      child: Stack(
        children: [
          AppColors.isDark(context)
              ? SvgPicture.asset(
                  "assets/images/home_cat_bg_dark.svg",
                  height: width * 0.5,
                  width: width * 0.5,
                  fit: BoxFit.fill,
                ).center()
              : Image.asset("assets/images/home_cat_bg_light.png",
                      height: width * 0.5,
                      width: width * 0.5,
                      fit: BoxFit.fill)
                  .center(),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  SvgPicture.asset(
                    icon,
                    color: AppColors.isDark(context)
                        ? Colors.white
                        : AppColors.colorPrimary,
                    height: Device.screenType == ScreenType.tablet ? 4.h : 5.5.h,
                    width: Device.screenType == ScreenType.tablet ? 4.h : 5.5.h,
                    fit: BoxFit.contain,
                  ).paddingAll(0.5.h),
                  Visibility(
                    visible: count > 0,
                    child: Container(
                      height: 3.h,
                        width: 3.h,
                        decoration: boxDecorationRoundedWithShadow(100,
                          backgroundColor: Colors.redAccent
                        ),
                        child: Text("+$count", style: AppTextStyles.textSmallBold.copyWith(
                          color: Colors.white,
                          fontSize: Device.screenType == ScreenType.tablet ? 12.sp : 14.sp
                        ),).center()),
                  )
                ],
              ),
              Text(
                text,
                style: AppTextStyles.custom(
                    Device.screenType == ScreenType.tablet ? 15.sp : 18.sp,
                    FontWeight.bold,
                    AppColors.isDark(context)
                        ? Colors.white
                        : AppColors.colorPrimary),
              ),
            ],
          ).paddingSymmetric(vertical: 16).center()
        ],
      ),
    );
  }
}
