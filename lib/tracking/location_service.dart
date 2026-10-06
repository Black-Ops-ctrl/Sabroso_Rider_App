import 'dart:io';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

import '../core/store.dart';
import 'tracker.dart';

const String kServiceTitle = 'Sabroso Rider';
const String kServiceContent = 'On duty';

@pragma('vm:entry-point')
Future<void> serviceMain(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  final store = await Store.open();
  if (store.token == null || !store.onDuty) {
    service.stopSelf();
    return;
  }
  final tracker = Tracker(
    store: store,
    onStopped: (reason) => service.stopSelf(),
  );
  service.on('stop').listen((_) => tracker.stop('stopped'));
  service.on('flush').listen((_) => tracker.flush());
  await tracker.start();
}

@pragma('vm:entry-point')
Future<bool> serviceIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  Tracker? _iosTracker;

  Future<void> configure({bool onBoot = false}) async {
    if (!Platform.isAndroid) return;
    await FlutterBackgroundService().configure(
      androidConfiguration: AndroidConfiguration(
        onStart: serviceMain,
        autoStart: false,
        autoStartOnBoot: onBoot,
        isForegroundMode: true,
        initialNotificationTitle: kServiceTitle,
        initialNotificationContent: kServiceContent,
        foregroundServiceNotificationId: 7301,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: serviceMain,
        onBackground: serviceIosBackground,
      ),
    );
  }

  Future<bool> isRunning() async {
    if (Platform.isAndroid) return FlutterBackgroundService().isRunning();
    return _iosTracker?.running ?? false;
  }

  Future<bool> canTrack() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    final perm = await Geolocator.checkPermission();
    if (Platform.isAndroid) return perm == LocationPermission.always;
    return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
  }

  Future<bool> start() async {
    final store = await Store.open();
    await store.setOnDuty(true);
    if (!await canTrack()) return false;
    if (Platform.isAndroid) {
      await configure(onBoot: true);
      final svc = FlutterBackgroundService();
      if (!await svc.isRunning()) await svc.startService();
      return true;
    }
    if (_iosTracker?.running ?? false) return true;
    final t = Tracker(store: store, onStopped: (_) {});
    _iosTracker = t;
    await t.start();
    return true;
  }

  Future<void> stop() async {
    final store = await Store.open();
    await store.setOnDuty(false);
    if (Platform.isAndroid) {
      await configure(onBoot: false);
      final svc = FlutterBackgroundService();
      if (await svc.isRunning()) svc.invoke('stop');
      return;
    }
    await _iosTracker?.stop('stopped');
    _iosTracker = null;
  }

  Future<void> flushNow() async {
    if (Platform.isAndroid) {
      final svc = FlutterBackgroundService();
      if (await svc.isRunning()) svc.invoke('flush');
      return;
    }
    await _iosTracker?.flush();
  }
}
