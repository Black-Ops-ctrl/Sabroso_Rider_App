import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/api.dart';
import '../../core/config.dart';
import '../../core/device.dart';
import '../../core/json.dart';
import '../../core/live.dart';
import '../../core/models.dart';
import '../../core/store.dart';
import '../../services/notification_service.dart';
import '../../tracking/location_service.dart';

enum RestoreResult { none, signedIn, offline }

class SessionProvider extends ChangeNotifier with WidgetsBindingObserver {
  SessionProvider(this.api, this.store) : notifications = NotificationService(api) {
    Api.onSignedOut = _signedOutByServer;
  }

  final Api api;
  final Store store;
  final NotificationService notifications;

  Rider? rider;
  String? restoreError;
  bool _started = false;
  bool _observing = false;
  bool _signingOut = false;

  LiveClient? _live;
  Timer? _poll;
  Timer? _debounce;
  final Set<String> _pending = <String>{};
  final StreamController<Set<String>> _changes = StreamController<Set<String>>.broadcast();

  VoidCallback? onCleared;
  VoidCallback? onSignedOut;

  Stream<Set<String>> get changes => _changes.stream;
  bool get signedIn => api.hasToken;
  bool get started => _started;

  Future<RestoreResult> restore() async {
    restoreError = null;
    api.token = store.token;
    if (!api.hasToken) return RestoreResult.none;
    try {
      rider = Rider.fromJson(await api.get('/rider/me'));
      _start();
      notifyListeners();
      return RestoreResult.signedIn;
    } on ApiException catch (e) {
      if (e.signedOut || !api.hasToken) {
        await _clear();
        return RestoreResult.none;
      }
      restoreError = e.message;
      _start();
      notifyListeners();
      return RestoreResult.offline;
    } catch (_) {
      restoreError = Api.noResponse;
      _start();
      notifyListeners();
      return RestoreResult.offline;
    }
  }

  Future<void> login(String username, String password) async {
    final device = await DeviceIdentity.read(store);
    final data = asMap(await api.post('/rider/login', <String, dynamic>{'username': username.trim(), 'password': password, ...device.toJson()}));
    final token = asString(data['token']);
    if (token.isEmpty) throw ApiException('Something went wrong. Try again', 500);
    api.token = token;
    await store.setToken(token);
    rider = Rider.fromJson(data['rider']);
    _start();
    notifyListeners();
  }

  void _start() {
    _started = true;
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    _startLive();
    _poll?.cancel();
    _poll = Timer.periodic(AppConfig.profilePoll, (_) => refreshMe());
    syncTracking();
    notifications.register();
  }

  void _startLive() {
    _live?.stop();
    final token = api.token;
    if (token == null || token.isEmpty) return;
    _live = LiveClient(token: token, onChange: _onLive, onUnauthorized: refreshMe)..start();
  }

  void _onLive(List<String> tables) {
    if (tables.isEmpty) {
      _pending.add('*');
    } else {
      _pending.addAll(tables);
    }
    _debounce?.cancel();
    _debounce = Timer(AppConfig.liveDebounce, () async {
      final set = Set<String>.from(_pending);
      _pending.clear();
      if (set.contains('*') || set.contains('riders') || set.contains('rider_notifications') || set.contains('shops')) {
        await refreshMe();
      }
      if (!_changes.isClosed && api.hasToken) _changes.add(set);
    });
  }

  Future<void> refreshMe() async {
    if (!api.hasToken) return;
    try {
      rider = Rider.fromJson(await api.get('/rider/me'));
      notifyListeners();
      await syncTracking();
    } catch (_) {}
  }

  void setRider(Rider r) {
    rider = r;
    notifyListeners();
  }

  void adjustUnread(int unread) {
    final r = rider;
    if (r == null) return;
    rider = Rider(
      id: r.id,
      code: r.code,
      empId: r.empId,
      name: r.name,
      phone: r.phone,
      username: r.username,
      password: r.password,
      joined: r.joined,
      status: r.status,
      unread: unread < 0 ? 0 : unread,
      onDuty: r.onDuty,
      onDutyAt: r.onDutyAt,
      deliveryStatus: r.deliveryStatus,
      openOrders: r.openOrders,
      shop: r.shop,
    );
    notifyListeners();
  }

  Future<void> syncTracking() async {
    final r = rider;
    if (r == null) return;
    try {
      if (r.onDuty) {
        final running = await LocationService.instance.isRunning();
        if (!running) await LocationService.instance.start();
      } else if (store.onDuty || await LocationService.instance.isRunning()) {
        await LocationService.instance.stop();
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      await api.post('/rider/logout');
    } on ApiException catch (e) {
      if (!e.signedOut) rethrow;
    }
    try {
      await LocationService.instance.stop();
    } catch (_) {}
    await _clear();
    notifyListeners();
  }

  void _signedOutByServer() {
    if (_signingOut) return;
    _signingOut = true;
    final wasStarted = _started;
    () async {
      try {
        await LocationService.instance.stop();
      } catch (_) {}
      await _clear();
      notifyListeners();
      _signingOut = false;
      if (wasStarted) {
        final cb = onSignedOut;
        if (cb != null) cb();
      }
    }();
  }

  Future<void> _clear() async {
    _live?.stop();
    _live = null;
    _poll?.cancel();
    _poll = null;
    _debounce?.cancel();
    _pending.clear();
    _started = false;
    api.token = null;
    rider = null;
    await store.clearSession();
    final cb = onCleared;
    if (cb != null) cb();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _started && api.hasToken) {
      _startLive();
      refreshMe();
      _onLive(const <String>[]);
      LocationService.instance.flushNow().catchError((Object _) {});
    }
  }

  @override
  void dispose() {
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    _live?.stop();
    _poll?.cancel();
    _debounce?.cancel();
    _changes.close();
    super.dispose();
  }
}
