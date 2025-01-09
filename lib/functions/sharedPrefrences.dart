// ignore_for_file: file_names

import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/themeCubit.dart';

class ThemePreferences {
  static const String _themeKey = 'theme';

  Future<ThemeModeEnum> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemeModeEnum.values[prefs.getInt(_themeKey) ?? 0];
  }

  Future<void> setTheme(ThemeModeEnum theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
  }
}
