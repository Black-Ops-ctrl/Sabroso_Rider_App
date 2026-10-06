import 'package:flutter/foundation.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../tracking/location_service.dart';

class OrdersProvider extends ChangeNotifier {
  OrdersProvider(this.api);

  final Api api;

  List<RiderOrder> rows = const <RiderOrder>[];
  StatusCounts counts = const StatusCounts();
  String filter = 'ALL';
  bool loading = false;
  bool loaded = false;
  String? error;
  final Set<int> busy = <int>{};
  final Set<int> _handledHere = <int>{};
  bool _fetching = false;

  void Function(String message, String? detail)? onNotice;

  List<RiderOrder> get visible => filter == 'ALL' ? rows : rows.where((o) => o.status == filter).toList();

  int get activeCount => counts.active;

  void setFilter(String f) {
    if (filter == f) return;
    filter = f;
    notifyListeners();
  }

  void reset() {
    rows = const <RiderOrder>[];
    counts = const StatusCounts();
    filter = 'ALL';
    loading = false;
    loaded = false;
    error = null;
    busy.clear();
    _handledHere.clear();
    notifyListeners();
  }

  Future<void> load({bool silent = false}) async {
    if (!api.hasToken || _fetching) return;
    _fetching = true;
    if (!silent) {
      loading = true;
      notifyListeners();
    }
    try {
      final today = TodayOrders.fromJson(await api.get('/rider/today'));
      _announce(today.rows);
      rows = today.rows;
      counts = today.counts;
      loaded = true;
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Something went wrong. Try again';
    } finally {
      _fetching = false;
      loading = false;
      notifyListeners();
    }
  }

  void _announce(List<RiderOrder> next) {
    if (!loaded) return;
    final cb = onNotice;
    if (cb == null) return;
    final before = <int, RiderOrder>{for (final o in rows) o.id: o};
    final after = <int, RiderOrder>{for (final o in next) o.id: o};
    for (final o in next) {
      if (o.isActive && !(before[o.id]?.isActive ?? false) && !before.containsKey(o.id)) {
        cb('New order assigned', '${o.code} · ${o.customer.address}');
      }
    }
    for (final o in rows) {
      if (!o.isActive || _handledHere.contains(o.id)) continue;
      final now = after[o.id];
      if (now == null) {
        cb('${o.code} was moved to another rider', null);
      } else if (now.isCancelled) {
        cb('${o.code} was cancelled', now.cancelledBy.isEmpty ? null : 'By ${now.cancelledBy}');
      }
    }
  }

  Future<ActionResult> outForDelivery(RiderOrder o) => _act(
        o,
        'out-for-delivery',
        null,
        '${o.code} is out for delivery',
        "Couldn't update ${o.code}. Try again",
      );

  Future<ActionResult> delivered(RiderOrder o) => _act(
        o,
        'delivered',
        null,
        '${o.code} delivered',
        "Couldn't mark ${o.code} delivered",
      );

  Future<ActionResult> cancel(RiderOrder o, String reason) {
    if (reason.trim().isEmpty) return Future<ActionResult>.value(const ActionResult(false, 'Enter the reason to cancel'));
    return _act(
      o,
      'cancel',
      <String, dynamic>{'reason': reason.trim()},
      '${o.code} cancelled',
      "Couldn't cancel ${o.code}. Try again",
    );
  }

  Future<ActionResult> _act(RiderOrder o, String action, Map<String, dynamic>? body, String ok, String fail) async {
    if (busy.contains(o.id)) return const ActionResult(false, '');
    busy.add(o.id);
    notifyListeners();
    try {
      try {
        await LocationService.instance.flushNow();
      } catch (_) {}
      await api.post('/rider/orders/${o.id}/$action', body);
      _handledHere.add(o.id);
      await load(silent: true);
      return ActionResult(true, ok);
    } on ApiException catch (e) {
      if (e.orderGone) {
        _handledHere.add(o.id);
        await load(silent: true);
      }
      return ActionResult(false, e.or(fail));
    } catch (_) {
      return ActionResult(false, fail);
    } finally {
      busy.remove(o.id);
      notifyListeners();
    }
  }

  Future<ActionResult> shopRoute() async {
    try {
      final shop = ShopRoute.fromJson(await api.get('/rider/shop'));
      if (shop.navigateUrl.isEmpty) return const ActionResult(false, 'Shop location is not set');
      return ActionResult(true, shop.navigateUrl);
    } on ApiException catch (e) {
      return ActionResult(false, e.or("Couldn't open the route to the shop"));
    } catch (_) {
      return const ActionResult(false, "Couldn't open the route to the shop");
    }
  }
}
