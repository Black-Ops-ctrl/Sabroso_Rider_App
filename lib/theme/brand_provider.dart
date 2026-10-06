import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../core/api.dart';
import '../core/json.dart';
import '../core/store.dart';
import 'app_colors.dart';

class Brand {
  const Brand({this.name = '', this.logo, this.svg = false});

  final String name;
  final Uint8List? logo;
  final bool svg;

  factory Brand.fromJson(dynamic data) {
    final m = asMap(data);
    final name = asString(m['name']);
    final raw = m['logo'];
    if (raw is! String || raw.isEmpty) return Brand(name: name);
    final match = RegExp(r'^data:([^;,]*)(;[^,]*)?,(.*)$', dotAll: true).firstMatch(raw);
    if (match == null) return Brand(name: name);
    final mime = (match.group(1) ?? '').toLowerCase();
    final isBase64 = (match.group(2) ?? '').toLowerCase().contains('base64');
    try {
      final body = match.group(3) ?? '';
      final bytes = isBase64
          ? base64Decode(body.replaceAll(RegExp(r'\s'), ''))
          : Uint8List.fromList(utf8.encode(Uri.decodeComponent(body)));
      return Brand(name: name, logo: bytes, svg: mime.contains('svg'));
    } catch (_) {
      return Brand(name: name);
    }
  }
}

class BrandProvider extends ChangeNotifier {
  BrandProvider(this.api, this.store) {
    final cached = store.brandJson;
    if (cached != null && cached.isNotEmpty) {
      try {
        brand = Brand.fromJson(jsonDecode(cached));
      } catch (_) {}
    }
  }

  final Api api;
  final Store store;

  Brand brand = const Brand();
  AppColors colors = AppColors.defaults;

  Future<void> load() async {
    await Future.wait(<Future<void>>[loadBrand(), loadTheme()]);
  }

  Future<void> loadBrand() async {
    try {
      final data = await api.get('/brand');
      final raw = jsonEncode(data);
      if (raw == store.brandJson) return;
      brand = Brand.fromJson(data);
      notifyListeners();
      await store.setBrandJson(raw);
    } catch (_) {}
  }

  Future<void> loadTheme() async {
    try {
      final data = asMap(await api.get('/app-theme'));
      final saved = <String, String>{};
      data.forEach((k, v) {
        if (v is String && v.trim().isNotEmpty) saved[k] = v.trim();
      });
      colors = AppColors.from(saved);
      notifyListeners();
    } catch (_) {}
  }
}
