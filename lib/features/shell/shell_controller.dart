import 'package:flutter/foundation.dart';

class ShellController extends ChangeNotifier {
  int index = 0;
  int previous = 0;
  final Map<int, double> _headers = <int, double>{};

  double? headerHeight(int i) => _headers[i];

  void go(int i) {
    if (i == index) return;
    previous = index;
    index = i;
    notifyListeners();
  }

  void setHeader(int i, double h) {
    final old = _headers[i];
    if (old != null && (old - h).abs() < 0.5) return;
    _headers[i] = h;
    if (i == index) notifyListeners();
  }

  void reset() {
    index = 0;
    previous = 0;
    notifyListeners();
  }
}
