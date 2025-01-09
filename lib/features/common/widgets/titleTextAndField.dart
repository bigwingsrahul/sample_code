// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:techtruckers/config/theme/app_colors.dart';
import 'package:techtruckers/config/theme/app_text_styles.dart';

class TitleTextAndField extends StatelessWidget {
  const TitleTextAndField({
    super.key,
    required this.title,
    this.isRequired = false,
    this.obsecure = false,
    this.titleColor,
    this.fieldColor,
    this.textColor,
    this.onTapEvent,
    this.keyboardType,
    this.suffixWidget = const Text(''),
    required this.controller,
    this.canNotUpdate = false,
    this.borderColor,
  });

  final String title;
  final bool isRequired;
  final bool obsecure;
  final Widget suffixWidget;
  final TextEditingController controller;
  final bool canNotUpdate;
  final TextInputType? keyboardType;
  final Color? titleColor;
  final Color? textColor;
  final Color? fieldColor;
  final Color? borderColor;
  final VoidCallback? onTapEvent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: title,
                style: AppTextStyles.textBodySemiBold.copyWith(color: titleColor ?? AppColors.blackWhiteText(context)),
                children: [
                  TextSpan(text: isRequired ? "  *" : "", style: AppTextStyles.textBodySemiBold.copyWith(color: Colors.redAccent)),
                ],
              ),
            ).expand()
          ],
        ),
        4.height,
        Container(
          height: 42,
          decoration: BoxDecoration(
              color: fieldColor ?? (AppColors.isDark(context) ? AppColors.cardDarkColor : Colors.white),
              border: Border.all(color: borderColor ?? AppColors.getPrimaryColor(context))),
          child: Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: TextFormField(
              controller: controller,
              readOnly: canNotUpdate,
              onTap: onTapEvent,
              obscureText: obsecure,
              keyboardType: keyboardType ?? TextInputType.text,
              style: AppTextStyles.textBodyNormal.copyWith(color: textColor),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                isCollapsed: true,
                // contentPadding: EdgeInsets.all(10.0),
                suffixIcon: suffixWidget,
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
