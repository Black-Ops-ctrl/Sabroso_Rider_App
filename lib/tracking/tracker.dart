import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';

import '../core/api.dart';
import '../core/config.dart';
import '../core/store.dart';

class Tracker {
  Tracker({required this.store, required this.onStopped});

  final Store store;
  final void Function(String reason) onStopped;

  final List<Map<String, dynamic>> _buffer = [];
  StreamSubscription<Position>? _positions;
  Timer? _timer;
  bool _sending = false;
  bool _running = false;
  DateTime _lastPoint = DateTime.fromMillisecondsSinceEpoch(0);

  bool get running => _running;

  LocationSettings _settings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: AppConfig.locationEverySeconds),
      );
    }
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 0);
  }

  Future<void> start() async {
    if (_running) return;
    _running = true;
    _buffer
      ..clear()
      ..addAll(store.readBuffer());
    _positions = Geolocator.getPositionStream(locationSettings: _settings()).listen(_onPosition, onError: (_) {});
    _timer = Timer.periodic(const Duration(seconds: AppConfig.locationEverySeconds), (_) => _tick());
  }

  Future<void> _tick() async {
    if (DateTime.now().difference(_lastPoint).inSeconds >= AppConfig.locationEverySeconds * 2) {
      try {
        final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high))
            .timeout(const Duration(seconds: 8));
        _onPosition(p);
      } catch (_) {}
    }
    await flush();
  }

  void _onPosition(Position p) {
    final now = DateTime.now();
    if (now.difference(_lastPoint).inMilliseconds < (AppConfig.locationEverySeconds * 1000) - 800) return;
    _lastPoint = now;
    _buffer.add({
      'lat': p.latitude,
      'lng': p.longitude,
      'speed': p.speed.isFinite && p.speed >= 0 ? p.speed : null,
      'accuracy': p.accuracy.isFinite ? p.accuracy : null,
      'time': p.timestamp.millisecondsSinceEpoch,
    });
    if (_buffer.length > AppConfig.maxBufferedPoints) {
      _buffer.removeRange(0, _buffer.length - AppConfig.maxBufferedPoints);
    }
  }

  Future<void> flush() async {
    if (_sending || _buffer.isEmpty) return;
    try {
      await store.prefs.reload();
    } catch (_) {}
    final token = store.token;
    if (token == null) {
      await stop('signed_out');
      return;
    }
    _sending = true;
    final batch = _buffer.take(AppConfig.maxPointsPerSend).toList();
    final api = Api(token: token);
    try {
      final res = await api.post('/rider/location', {'points': batch});
      _buffer.removeRange(0, batch.length);
      await store.writeBuffer(_buffer);
      if (res is Map && res['on_duty'] == false) {
        await store.setOnDuty(false);
        await stop('off_duty');
        return;
      }
    } on ApiException catch (e) {
      if (e.signedOut) {
        await store.clearSession();
        await stop('signed_out');
      } else {
        await store.writeBuffer(_buffer);
      }
    } catch (_) {
      await store.writeBuffer(_buffer);
    } finally {
      api.close();
      _sending = false;
    }
  }

  Future<void> stop([String reason = 'stopped']) async {
    if (!_running) return;
    _running = false;
    _timer?.cancel();
    _timer = null;
    await _positions?.cancel();
    _positions = null;
    if (reason == 'off_duty' || reason == 'stopped') {
      if (_buffer.isNotEmpty && !_sending) {
        final token = store.token;
        if (token != null) {
          final api = Api(token: token);
          try {
            final last = _buffer.take(AppConfig.maxPointsPerSend).toList();
            await api.post('/rider/location', {'points': last});
            _buffer.removeRange(0, last.length);
          } catch (_) {
          } finally {
            api.close();
          }
        }
      }
      await store.writeBuffer(_buffer);
    }
    onStopped(reason);
  }
}
