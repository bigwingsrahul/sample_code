// ignore_for_file: file_names

import 'package:bloc/bloc.dart';

import '../functions/sharedPrefrences.dart';

enum ThemeModeEnum { light, dark }

class ThemeCubit extends Cubit<ThemeModeEnum> {
  ThemeCubit(this.initialTheme, this.preferences) : super(initialTheme);

  final ThemeModeEnum initialTheme;
  final ThemePreferences preferences;

  void toggleTheme() {
    if (state == ThemeModeEnum.light) {
      preferences.setTheme(ThemeModeEnum.dark);
      emit(ThemeModeEnum.dark);
    } else {
      preferences.setTheme(ThemeModeEnum.light);
      emit(ThemeModeEnum.light);
    }
  }

  bool getTheme() {
    if (state == ThemeModeEnum.light) {
     return true;
    } else {
     return false;
    }
  }

}
