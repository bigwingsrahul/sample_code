import 'package:flutter/material.dart';
import 'package:techtruckers/config/theme/app_text_styles.dart';

class Tag extends StatelessWidget {
    const Tag(
      {super.key,
      required this.height,
      required this.width,
      required this.text,
      required this.color});
  final double width;
  final double height;
  final String text;
  final Color color;

 @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      child: Center(
        child: Text(
          text,
          style: AppTextStyles.textSmallNormal.copyWith(
              color: text.contains("Drop") ? Colors.white : Colors.black
          ),
        ),
      ),
    );
  }
}
