import 'package:flutter/foundation.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../tracking/location_service.dart';
import '../auth/session_provider.dart';

class DutyProvider extends ChangeNotifier {
  DutyProvider(this.api, this.session);

  final Api api;
  final SessionProvider session;

  bool busy = false;

  bool get onDuty => session.rider?.onDuty ?? false;
  DateTime? get since => session.rider?.onDutyAt;

  Future<ActionResult> setDuty(bool on, {required int activeOrders}) async {
    if (busy) return const ActionResult(false, '');
    if (!on && activeOrders > 0) return const ActionResult(false, 'Deliver all orders to go off duty');
    if (on && !await LocationService.instance.canTrack()) {
      return const ActionResult(false, 'Allow location all the time to go on duty');
    }
    busy = true;
    notifyListeners();
    try {
      final data = await api.patch('/rider/duty', <String, dynamic>{'on_duty': on});
      session.setRider(Rider.fromJson(data));
      try {
        if (on) {
          await LocationService.instance.start();
        } else {
          await LocationService.instance.stop();
        }
      } catch (_) {}
      return ActionResult(true, on ? 'You are on duty' : 'You are off duty');
    } on ApiException catch (e) {
      return ActionResult(false, e.or(on ? "Couldn't go on duty. Try again" : "Couldn't go off duty. Try again"));
    } catch (_) {
      return ActionResult(false, on ? "Couldn't go on duty. Try again" : "Couldn't go off duty. Try again");
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
