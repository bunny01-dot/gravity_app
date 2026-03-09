import 'package:flutter/widgets.dart';

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 18;
  static const double xxl = 24;

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: lg - 2,
  );
  static const EdgeInsets textButtonPadding = EdgeInsets.symmetric(
    horizontal: lg - 2,
    vertical: md - 2,
  );
}

class AppRadii {
  AppRadii._();

  static const double sm = 14;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
}
