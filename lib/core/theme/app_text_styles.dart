import 'package:flutter/material.dart';
import 'package:gravity_app/core/theme/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle dialogTitleLight = TextStyle(
    color: AppColors.lightDialogTitle,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle dialogContentLight = TextStyle(
    color: AppColors.lightDialogBody,
    fontSize: 15,
  );

  static const TextStyle dialogTitleDark = TextStyle(
    color: AppColors.white,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle snackBarContent = TextStyle(color: AppColors.white);
}
