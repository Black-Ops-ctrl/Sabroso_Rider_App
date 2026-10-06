import 'package:flutter/foundation.dart';

import '../../core/api.dart';
import '../../core/models.dart';

class HomeProvider extends ChangeNotifier {
  HomeProvider(this.api);

  final Api api;

  HomeStats? stats;
  bool loading = false;
  bool loaded = false;
  String? error;
  bool _fetching = false;

  void reset() {
    stats = null;
    loading = false;
    loaded = false;
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
      stats = HomeStats.fromJson(await api.get('/rider/home'));
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
}
