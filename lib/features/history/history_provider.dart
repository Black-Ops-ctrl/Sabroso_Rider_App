import 'package:flutter/foundation.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/models.dart';

class HistoryProvider extends ChangeNotifier {
  HistoryProvider(this.api);

  final Api api;

  DateTime? from;
  DateTime? to;
  DateTime? _appliedFrom;
  DateTime? _appliedTo;
  List<RiderOrder> rows = const <RiderOrder>[];
  HistorySummary summary = const HistorySummary();
  int page = 0;
  int pages = 0;
  int total = 0;
  bool loading = false;
  bool loadingMore = false;
  String? error;

  bool get canSearch => from != null && to != null;
  bool get hasResult => _appliedFrom != null && _appliedTo != null && page > 0;
  bool get searched => _appliedFrom != null && _appliedTo != null;
  bool get hasMore => page < pages;

  void reset() {
    from = null;
    to = null;
    _appliedFrom = null;
    _appliedTo = null;
    rows = const <RiderOrder>[];
    summary = const HistorySummary();
    page = 0;
    pages = 0;
    total = 0;
    loading = false;
    loadingMore = false;
    error = null;
    notifyListeners();
  }

  void setRange(DateTime? start, DateTime? end) {
    from = start;
    to = end;
    notifyListeners();
  }

  Future<ActionResult> show() async {
    final f = from;
    final t = to;
    if (f == null || t == null) return const ActionResult(false, 'Select a date range');
    _appliedFrom = f;
    _appliedTo = t;
    return _loadFirst(silent: false);
  }

  Future<void> refresh({bool silent = false}) async {
    if (!searched) return;
    await _loadFirst(silent: silent);
  }

  Future<ActionResult> _loadFirst({required bool silent}) async {
    final f = _appliedFrom;
    final t = _appliedTo;
    if (f == null || t == null || !api.hasToken) return const ActionResult(false, 'Select a date range');
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final res = HistoryPage.fromJson(await api.get('/rider/history?from=${Fmt.ymd(f)}&to=${Fmt.ymd(t)}&page=1'));
      if (_appliedFrom != f || _appliedTo != t) return const ActionResult(false, '');
      rows = res.rows;
      summary = res.summary;
      page = res.page;
      pages = res.pages;
      total = res.total;
      error = null;
      return const ActionResult(true, '');
    } on ApiException catch (e) {
      if (!silent) error = e.message;
      return ActionResult(false, e.or("Couldn't load orders. Try again"));
    } catch (_) {
      if (!silent) error = "Couldn't load orders. Try again";
      return const ActionResult(false, "Couldn't load orders. Try again");
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<ActionResult> loadMore() async {
    final f = _appliedFrom;
    final t = _appliedTo;
    if (f == null || t == null || loadingMore || loading || !hasMore) return const ActionResult(true, '');
    loadingMore = true;
    notifyListeners();
    try {
      final next = page + 1;
      final res = HistoryPage.fromJson(await api.get('/rider/history?from=${Fmt.ymd(f)}&to=${Fmt.ymd(t)}&page=$next'));
      if (_appliedFrom != f || _appliedTo != t) return const ActionResult(true, '');
      final seen = rows.map((o) => o.id).toSet();
      rows = <RiderOrder>[...rows, ...res.rows.where((o) => !seen.contains(o.id))];
      page = res.page;
      pages = res.pages;
      total = res.total;
      summary = res.summary;
      return const ActionResult(true, '');
    } on ApiException catch (e) {
      return ActionResult(false, e.or("Couldn't load more orders. Try again"));
    } catch (_) {
      return const ActionResult(false, "Couldn't load more orders. Try again");
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }
}
