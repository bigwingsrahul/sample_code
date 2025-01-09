import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:techtruckers/config/theme/app_colors.dart';
import 'package:techtruckers/config/theme/app_text_styles.dart';

class NoRecordWidget extends StatelessWidget {
  const NoRecordWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.sizeOf(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            AppColors.isDark(context)
                ? "assets/lottie/commonhistory_dark.json"
                : "assets/lottie/commonhistory_light.json",
            height: 150,
            width: double.infinity,
          ),
          SizedBox(
              width: size.width * 0.75,
              child: Text("There’s nothing here right now, check back later or explore other sections!",
                textAlign: TextAlign.center,
                style: AppTextStyles.textBodySemiBold,))
        ],
      ),
    );
  }
}
