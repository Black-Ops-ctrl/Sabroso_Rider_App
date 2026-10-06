import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

enum PhonePermission { gps, location, notifications, battery }

class PermissionState {
  const PermissionState({this.gps = false, this.location = false, this.notifications = false, this.battery = false});

  final bool gps;
  final bool location;
  final bool notifications;
  final bool battery;

  bool of(PhonePermission p) => switch (p) {
        PhonePermission.gps => gps,
        PhonePermission.location => location,
        PhonePermission.notifications => notifications,
        PhonePermission.battery => battery,
      };

  int get granted => <bool>[gps, location, notifications, battery].where((v) => v).length;

  bool get all => granted == 4;
}

class PermissionService {
  static Future<PermissionState> check() async {
    bool gps = false;
    bool location = false;
    bool notifications = false;
    bool battery = true;
    try {
      gps = await Geolocator.isLocationServiceEnabled();
    } catch (_) {}
    try {
      final perm = await Geolocator.checkPermission();
      location = perm == LocationPermission.always;
    } catch (_) {}
    try {
      notifications = await Permission.notification.isGranted;
    } catch (_) {}
    if (Platform.isAndroid) {
      try {
        battery = await Permission.ignoreBatteryOptimizations.isGranted;
      } catch (_) {
        battery = false;
      }
    }
    return PermissionState(gps: gps, location: location, notifications: notifications, battery: battery);
  }

  static Future<void> request(PhonePermission p) async {
    try {
      switch (p) {
        case PhonePermission.gps:
          await Geolocator.openLocationSettings();
          break;
        case PhonePermission.location:
          await _requestLocation();
          break;
        case PhonePermission.notifications:
          final st = await Permission.notification.request();
          if (st.isPermanentlyDenied) await openAppSettings();
          break;
        case PhonePermission.battery:
          if (Platform.isAndroid) {
            final st = await Permission.ignoreBatteryOptimizations.request();
            if (!st.isGranted) await openAppSettings();
          }
          break;
      }
    } catch (_) {}
  }

  static Future<void> openSettingsFor(PhonePermission p) async {
    try {
      if (p == PhonePermission.gps) {
        await Geolocator.openLocationSettings();
      } else {
        await openAppSettings();
      }
    } catch (_) {}
  }

  static Future<void> _requestLocation() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.whileInUse) {
      if (Platform.isAndroid) {
        final st = await Permission.locationAlways.request();
        if (!st.isGranted) await Geolocator.openAppSettings();
      } else {
        perm = await Geolocator.requestPermission();
        if (perm != LocationPermission.always) await Geolocator.openAppSettings();
      }
    } else if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }
  }

  static String label(PhonePermission p) => switch (p) {
        PhonePermission.gps => 'GPS',
        PhonePermission.location => 'Location access',
        PhonePermission.notifications => 'Notifications',
        PhonePermission.battery => 'Battery',
      };

  static String allowedMessage(PhonePermission p) => switch (p) {
        PhonePermission.gps => 'GPS is on',
        PhonePermission.location => 'Location access allowed',
        PhonePermission.notifications => 'Notifications allowed',
        PhonePermission.battery => 'Battery set to no restrictions',
      };

  static String failedMessage(PhonePermission p) => switch (p) {
        PhonePermission.gps => 'GPS is still off',
        PhonePermission.location => 'Location access not allowed',
        PhonePermission.notifications => 'Notifications not allowed',
        PhonePermission.battery => 'Battery is still restricted',
      };
}
