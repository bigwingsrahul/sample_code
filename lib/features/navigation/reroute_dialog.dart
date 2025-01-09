// ignore_for_file: file_names

import 'package:flutter/material.dart';

import 'package:getwidget/components/border/gf_border.dart';
import 'package:getwidget/types/gf_border_type.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:techtruckers/config/theme/app_colors.dart';
import 'package:techtruckers/config/theme/app_text_styles.dart';
import 'package:techtruckers/features/common/widgets/custom_gradient_button.dart';
import 'package:techtruckers/features/common/widgets/custom_outline_button.dart';


class RerouteDialog extends StatefulWidget {
    const RerouteDialog({super.key,required this.onAccept, required this.location});
    final String location;
    final VoidCallback onAccept;

  @override
  State<RerouteDialog> createState() => _RerouteDialogState();
}

class _RerouteDialogState extends State<RerouteDialog> {

 @override
  Widget build(BuildContext context) {
    return Column(
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
                  Image.asset("assets/dispatchicon.png", color: AppColors.blackWhiteText(context),),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    "Location updated!",
                    style: AppTextStyles.textBodyBold,
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "The location where you were heading to has been changed to ${widget.location}. Do you want to re route?",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.textSmallNormal,
                    ),
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
                          borderColor: AppColors.colorPrimary, onTapEvent: widget.onAccept,
                        ),
                      ).expand(),
                      16.width,
                      SizedBox(
                        height: 4.h,
                        child: CustomOutlineButton(
                          text: "Cancel",
                          borderColor: Colors.black, onTapEvent: () {
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
    );
  }
}
