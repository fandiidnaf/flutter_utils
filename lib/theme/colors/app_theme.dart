import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppThemeExt extends ThemeExtension<AppThemeExt> {
  final Color scaffoldColor;

  const AppThemeExt({required this.scaffoldColor});

  @override
  ThemeExtension<AppThemeExt> copyWith({Color? scaffoldColor}) {
    return AppThemeExt(scaffoldColor: scaffoldColor ?? this.scaffoldColor);
  }

  @override
  ThemeExtension<AppThemeExt> lerp(
    covariant ThemeExtension<AppThemeExt>? other,
    double t,
  ) {
    if (other is! AppThemeExt) return this;
    return AppThemeExt(
      scaffoldColor: Color.lerp(scaffoldColor, other.scaffoldColor, t)!,
    );
  }
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    extensions: [AppThemeExt(scaffoldColor: AppColors.white)],
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    extensions: [AppThemeExt(scaffoldColor: AppColors.black)],
  );
}

extension AppThemeExts on BuildContext {
  // ex: context.colors.scaffoldColor
  AppThemeExt get colors => Theme.of(this).extension<AppThemeExt>()!;
}
