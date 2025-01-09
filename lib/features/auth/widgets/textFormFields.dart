// ignore_for_file: camel_case_types, file_names, non_ ant_identifier_names

import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

typedef onValidate = String? Function(String? val);

class CustomTextEditingWidget extends StatefulWidget {
    const CustomTextEditingWidget(
      {super.key,
      required this.height,
      required this.width,
      required this.icon,
      required this.obscureText,
      required this.controller,
      this.hintText = "", this.borderRadius = 1000, this.validator, this.autofillHints});
  final double height;
  final String hintText;
  final double width;
  final Widget icon;
  final double borderRadius;
  final bool obscureText;
  final onValidate? validator;
  final TextEditingController controller;
  final Iterable<String>? autofillHints;

  @override
  State<CustomTextEditingWidget> createState() => _CustomTextEditingWidgetState();
}

class _CustomTextEditingWidgetState extends State<CustomTextEditingWidget> {

 @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: Colors.blue, width: 2),
        color: Colors.white,
      ),
      child: Center(
        // Wrapping TextFormField with Center widget
        child: TextFormField(
          textAlignVertical: TextAlignVertical.center,
          controller: widget.controller,
          autofillHints: widget.autofillHints,
          obscureText: widget.obscureText,
          validator: widget.validator,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.black
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            isCollapsed: true,
            contentPadding:   EdgeInsets.only(left: 10),
            suffixIcon: widget.icon,
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
