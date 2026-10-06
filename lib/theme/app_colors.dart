import 'package:flutter/material.dart';

const Map<String, String> kThemeDefaults = <String, String>{
  'header-top': '#2e0654',
  'header-bottom': '#5b21b6',
  'background': '#f6f4f1',
  'card': '#ffffff',
  'accent': '#6d28d9',
  'text': '#1c1726',
  'muted': '#8a8298',
  'nav-top': '#2e0654',
  'nav-bottom': '#6d28d9',
  'nav-pill': '#ffffff',
  'nav-active': '#6d28d9',
  'slide-top': '#3b0764',
  'slide-bottom': '#6d28d9',
  'ofd-top': '#22d3ee',
  'ofd-bottom': '#0891b2',
  'delivered-top': '#4ade80',
  'delivered-bottom': '#16a34a',
  'cancel': '#dc2626',
  'go-shop-top': '#f59e0b',
  'go-shop-bottom': '#f97316',
  'success': '#16a34a',
  'error': '#dc2626',
  'info': '#6d28d9',
  'ring': '#16a34a',
  'chart-bar': '#7c3aed',
};

Color? parseCssColor(String? input) {
  if (input == null) return null;
  final s = input.trim().toLowerCase();
  final hex = RegExp(r'^#([0-9a-f]{3,8})$').firstMatch(s);
  if (hex != null) {
    var h = hex.group(1)!;
    if (h.length == 3 || h.length == 4) h = h.split('').map((c) => '$c$c').join();
    if (h.length == 6) h = '${h}ff';
    if (h.length != 8) return null;
    int part(int i) => int.parse(h.substring(i, i + 2), radix: 16);
    return Color.fromARGB(part(6), part(0), part(2), part(4));
  }
  final rgb = RegExp(r'^rgba?\(\s*([\d.]+)[\s,]+([\d.]+)[\s,]+([\d.]+)(?:[\s,/]+([\d.]+%?))?\s*\)$').firstMatch(s);
  if (rgb != null) {
    int ch(int i) => double.parse(rgb.group(i)!).clamp(0, 255).round();
    var a = 1.0;
    final ag = rgb.group(4);
    if (ag != null) {
      a = ag.endsWith('%') ? double.parse(ag.substring(0, ag.length - 1)) / 100 : double.parse(ag);
    }
    return Color.fromARGB((a.clamp(0.0, 1.0) * 255).round(), ch(1), ch(2), ch(3));
  }
  return null;
}

Color fade(Color c, double opacity) => c.withAlpha((opacity.clamp(0.0, 1.0) * 255).round());

class AppColors {
  const AppColors({
    required this.headerTop,
    required this.headerBottom,
    required this.background,
    required this.card,
    required this.accent,
    required this.text,
    required this.muted,
    required this.navTop,
    required this.navBottom,
    required this.navPill,
    required this.navActive,
    required this.slideTop,
    required this.slideBottom,
    required this.ofdTop,
    required this.ofdBottom,
    required this.deliveredTop,
    required this.deliveredBottom,
    required this.cancel,
    required this.goShopTop,
    required this.goShopBottom,
    required this.success,
    required this.error,
    required this.info,
    required this.ring,
    required this.chartBar,
  });

  final Color headerTop;
  final Color headerBottom;
  final Color background;
  final Color card;
  final Color accent;
  final Color text;
  final Color muted;
  final Color navTop;
  final Color navBottom;
  final Color navPill;
  final Color navActive;
  final Color slideTop;
  final Color slideBottom;
  final Color ofdTop;
  final Color ofdBottom;
  final Color deliveredTop;
  final Color deliveredBottom;
  final Color cancel;
  final Color goShopTop;
  final Color goShopBottom;
  final Color success;
  final Color error;
  final Color info;
  final Color ring;
  final Color chartBar;

  static const Color border = Color(0xFFECE8F4);
  static const Color text2 = Color(0xFF4A4458);
  static const Color amber = Color(0xFFF59E0B);
  static const Color assigned = Color(0xFF7C3AED);
  static const Color assignedSoft = Color(0xFFF1EAFE);
  static const Color ofd = Color(0xFF0891B2);
  static const Color ofdSoft = Color(0xFFE0F7FB);
  static const Color delivered = Color(0xFF16A34A);
  static const Color deliveredSoft = Color(0xFFE6F7EC);
  static const Color cancelledSoft = Color(0xFFFDECEC);
  static const Color lavender = Color(0xFFEDE9FE);
  static const Color greenSoft = Color(0xFFE8F6EE);

  factory AppColors.from(Map<String, String> saved) {
    Color c(String key) => parseCssColor(saved[key]) ?? parseCssColor(kThemeDefaults[key]) ?? const Color(0xFF6D28D9);
    return AppColors(
      headerTop: c('header-top'),
      headerBottom: c('header-bottom'),
      background: c('background'),
      card: c('card'),
      accent: c('accent'),
      text: c('text'),
      muted: c('muted'),
      navTop: c('nav-top'),
      navBottom: c('nav-bottom'),
      navPill: c('nav-pill'),
      navActive: c('nav-active'),
      slideTop: c('slide-top'),
      slideBottom: c('slide-bottom'),
      ofdTop: c('ofd-top'),
      ofdBottom: c('ofd-bottom'),
      deliveredTop: c('delivered-top'),
      deliveredBottom: c('delivered-bottom'),
      cancel: c('cancel'),
      goShopTop: c('go-shop-top'),
      goShopBottom: c('go-shop-bottom'),
      success: c('success'),
      error: c('error'),
      info: c('info'),
      ring: c('ring'),
      chartBar: c('chart-bar'),
    );
  }

  static final AppColors defaults = AppColors.from(const <String, String>{});

  LinearGradient get header => LinearGradient(
        begin: const Alignment(-0.6, -1),
        end: const Alignment(0.6, 1),
        colors: <Color>[headerTop, headerBottom],
      );

  LinearGradient get nav => LinearGradient(colors: <Color>[navTop, navBottom]);

  LinearGradient get slide => LinearGradient(colors: <Color>[slideTop, slideBottom]);

  LinearGradient get ofdButton => LinearGradient(colors: <Color>[ofdTop, ofdBottom]);

  LinearGradient get deliveredButton => LinearGradient(colors: <Color>[deliveredTop, deliveredBottom]);

  LinearGradient get goShop => LinearGradient(colors: <Color>[goShopTop, goShopBottom]);

  LinearGradient get cancelButton => LinearGradient(colors: <Color>[Color.lerp(cancel, Colors.white, 0.25)!, cancel]);

  LinearGradient get accentButton => LinearGradient(colors: <Color>[Color.lerp(accent, Colors.black, 0.2)!, Color.lerp(accent, Colors.white, 0.12)!]);

  Color statusColor(String status) {
    switch (status) {
      case 'ASSIGNED':
        return assigned;
      case 'OUT_FOR_DELIVERY':
        return ofd;
      case 'DELIVERED':
        return delivered;
      case 'CANCELLED':
        return cancel;
      default:
        return muted;
    }
  }

  Color statusSoft(String status) {
    switch (status) {
      case 'ASSIGNED':
        return assignedSoft;
      case 'OUT_FOR_DELIVERY':
        return ofdSoft;
      case 'DELIVERED':
        return deliveredSoft;
      case 'CANCELLED':
        return cancelledSoft;
      default:
        return border;
    }
  }
}
