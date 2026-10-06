import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Store {
  static const _token = 'rider_token';
  static const _onDuty = 'rider_on_duty';
  static const _buffer = 'rider_location_buffer';
  static const _brand = 'brand_cache';
  static const _device = 'device_id';

  final SharedPreferences prefs;
  Store._(this.prefs);

  static Future<Store> open() async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    return Store._(p);
  }

  String? get token => prefs.getString(_token);
  bool get onDuty => prefs.getBool(_onDuty) ?? false;
  String? get brandJson => prefs.getString(_brand);
  String? get deviceId => prefs.getString(_device);

  Future<void> setDeviceId(String value) => prefs.setString(_device, value);

  Future<void> setBrandJson(String value) => prefs.setString(_brand, value);

  Future<void> setToken(String? value) async {
    if (value == null || value.isEmpty) {
      await prefs.remove(_token);
    } else {
      await prefs.setString(_token, value);
    }
  }

  Future<void> setOnDuty(bool value) => prefs.setBool(_onDuty, value);

  List<Map<String, dynamic>> readBuffer() {
    final raw = prefs.getString(_buffer);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> writeBuffer(List<Map<String, dynamic>> points) async {
    if (points.isEmpty) {
      await prefs.remove(_buffer);
    } else {
      await prefs.setString(_buffer, jsonEncode(points));
    }
  }

  Future<void> clearSession() async {
    await prefs.remove(_token);
    await prefs.remove(_onDuty);
    await prefs.remove(_buffer);
  }
}
