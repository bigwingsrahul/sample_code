import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:techtruckers/config/theme/app_text_styles.dart';

class LoaderDialog {
  // Singleton pattern to ensure only one instance of the dialog exists
  static final LoaderDialog _instance = LoaderDialog._internal();

  factory LoaderDialog() => _instance;

  LoaderDialog._internal();

  // To keep track of the current context and dialog
  BuildContext? _context;
  bool _isShowing = false;
  late Dialog _dialog;

  // Function to show the loader dialog
  void show(BuildContext context, String message) {
    if (_isShowing) return; // Prevent showing multiple dialogs

    _context = context;
    _dialog = Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white,),
            16.height,
            Text(message, style: AppTextStyles.textSmallTitleSemiBold.copyWith(
              color: Colors.white
            ),)
          ],
        ),
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dismissing dialog by tapping outside
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            // Handle the back button press
            hide();
            return false; // Prevents dialog from being dismissed by back button
          },
          child: _dialog,
        );
      },
    );

    _isShowing = true;
  }

  // Function to hide the loader dialog
  void hide() {
    if (!_isShowing || _context == null) return;

    Navigator.of(_context!).pop(); // Close the dialog
    _isShowing = false;
    _context = null; // Clear the context
  }
}
