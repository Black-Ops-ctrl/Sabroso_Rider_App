import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';

import 'store.dart';

class DeviceIdentity {
  const DeviceIdentity({required this.id, required this.name, required this.platform});

  final String id;
  final String name;
  final String platform;

  Map<String, dynamic> toJson() => <String, dynamic>{'device_id': id, 'device_name': name, 'platform': platform};

  static DeviceIdentity? _cached;

  static Future<DeviceIdentity> read(Store store) async {
    final hit = _cached;
    if (hit != null) return hit;
    var id = store.deviceId ?? '';
    if (id.isEmpty) {
      id = _newId();
      await store.setDeviceId(id);
    }
    final value = DeviceIdentity(id: id, name: await _name(), platform: _platform());
    _cached = value;
    return value;
  }

  static String _newId() {
    final r = Random.secure();
    return List<String>.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  static String _platform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return Platform.operatingSystem;
  }

  static Future<String> _name() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        final maker = a.manufacturer.isEmpty ? '' : '${a.manufacturer[0].toUpperCase()}${a.manufacturer.substring(1)}';
        final model = a.model.toLowerCase().startsWith(a.manufacturer.toLowerCase()) ? a.model : '$maker ${a.model}';
        return model.trim();
      }
      if (Platform.isIOS) {
        final i = await info.iosInfo;
        return '${i.model} (iOS ${i.systemVersion})'.trim();
      }
    } catch (_) {}
    return 'Unknown phone';
  }
}
