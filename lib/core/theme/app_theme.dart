import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'IBMPlexSans',
    scaffoldBackgroundColor: AppColors.white,
    primaryColor: AppColors.hmBlue,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      elevation: 0,
      foregroundColor: AppColors.gray1,
    ),

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.hmBlue,
      primary: AppColors.hmBlue,
      secondary: AppColors.hmGreen,
      error: AppColors.warningRed,
      background: AppColors.white,
    ),
  );
}
