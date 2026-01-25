import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle body = TextStyle(
    fontFamily: 'IBMPlexSans',
    fontSize: 14,
    height: 1.5,
    color: AppColors.gray1,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: 'IBMPlexSans',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.gray1,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
    color: AppColors.gray1,
  );
}
