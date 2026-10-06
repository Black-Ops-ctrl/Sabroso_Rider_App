import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'app_colors.dart';
import 'brand_provider.dart';

extension ScaleX on BuildContext {
  double get scale {
    final w = MediaQuery.sizeOf(this).width;
    return (w / 390).clamp(0.82, 1.12);
  }

  double sp(double v) => v * scale;

  double get topInset => MediaQuery.paddingOf(this).top;

  double get bottomInset => MediaQuery.paddingOf(this).bottom;

  AppColors get palette => watch<BrandProvider>().colors;

  AppColors get paletteNow => read<BrandProvider>().colors;
}

const SystemUiOverlayStyle kLightBar = SystemUiOverlayStyle(
  statusBarColor: Color(0x00000000),
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: Color(0xFFF6F4F1),
  systemNavigationBarIconBrightness: Brightness.dark,
);

const SystemUiOverlayStyle kDarkBar = SystemUiOverlayStyle(
  statusBarColor: Color(0x00000000),
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: Color(0xFFF6F4F1),
  systemNavigationBarIconBrightness: Brightness.dark,
);
