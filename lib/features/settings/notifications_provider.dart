import 'package:flutter/foundation.dart';

import '../../core/api.dart';
import '../../core/json.dart';
import '../../core/models.dart';
import '../auth/session_provider.dart';

class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider(this.api, this.session);

  final Api api;
  final SessionProvider session;

  List<RiderNotification> rows = const <RiderNotification>[];
  int page = 0;
  int pages = 0;
  bool loading = false;
  bool loadingMore = false;
  bool loaded = false;
  bool marking = false;
  String? error;
  bool _fetching = false;

  int get unread => session.rider?.unread ?? rows.where((n) => n.unread).length;
  bool get hasMore => page < pages;

  void reset() {
    rows = const <RiderNotification>[];
    page = 0;
    pages = 0;
    loading = false;
    loadingMore = false;
    loaded = false;
    marking = false;
    error = null;
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
      final res = NotificationPage.fromJson(await api.get('/rider/notifications?page=1'));
      rows = res.rows;
      page = res.page;
      pages = res.pages;
      loaded = true;
      error = null;
      session.adjustUnread(res.unread);
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

  Future<void> loadMore() async {
    if (loadingMore || loading || !hasMore || !api.hasToken) return;
    loadingMore = true;
    notifyListeners();
    try {
      final res = NotificationPage.fromJson(await api.get('/rider/notifications?page=${page + 1}'));
      final seen = rows.map((n) => n.id).toSet();
      rows = <RiderNotification>[...rows, ...res.rows.where((n) => !seen.contains(n.id))];
      page = res.page;
      pages = res.pages;
    } catch (_) {
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<ActionResult> markAllRead() async {
    if (marking) return const ActionResult(false, '');
    marking = true;
    notifyListeners();
    try {
      final res = asMap(await api.post('/rider/notifications/read', <String, dynamic>{}));
      rows = rows.map((n) => n.markRead()).toList();
      session.adjustUnread(asInt(res['unread']) ?? 0);
      return const ActionResult(true, 'All notifications marked read');
    } on ApiException catch (e) {
      return ActionResult(false, e.or("Couldn't mark as read. Try again"));
    } catch (_) {
      return const ActionResult(false, "Couldn't mark as read. Try again");
    } finally {
      marking = false;
      notifyListeners();
    }
  }

  Future<void> markRead(RiderNotification n) async {
    if (!n.unread) return;
    rows = rows.map((x) => x.id == n.id ? x.markRead() : x).toList();
    notifyListeners();
    try {
      final res = asMap(await api.post('/rider/notifications/read', <String, dynamic>{'ids': <int>[n.id]}));
      session.adjustUnread(asInt(res['unread']) ?? 0);
    } catch (_) {}
  }
}
