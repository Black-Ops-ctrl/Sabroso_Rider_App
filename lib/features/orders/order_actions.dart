import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../services/launcher.dart';
import '../../widgets/toast.dart';
import 'orders_provider.dart';
import 'widgets/cancel_sheet.dart';

class OrderActions {
  static Future<bool> advance(BuildContext context, RiderOrder o) async {
    final orders = context.read<OrdersProvider>();
    final ActionResult r;
    if (o.isAssigned) {
      r = await orders.outForDelivery(o);
    } else if (o.isOut) {
      r = await orders.delivered(o);
    } else {
      return false;
    }
    if (r.message.isNotEmpty) Toast.result(r.ok, r.message);
    return r.ok;
  }

  static Future<bool> cancel(BuildContext context, RiderOrder o) async {
    final done = await CancelSheet.show(context, o);
    return done ?? false;
  }

  static Future<void> call(String name, String phone) async {
    final ok = await Launcher.call(phone);
    if (ok) {
      Toast.info(name.isEmpty ? 'Calling' : 'Calling $name');
    } else {
      Toast.error("Couldn't open the dialer");
    }
  }

  static Future<void> navigate(Place place) async {
    final ok = await Launcher.directions(lat: place.lat, lng: place.lng, address: place.address);
    if (ok) {
      Toast.info('Opening Google Maps');
    } else {
      Toast.error("Couldn't open Google Maps");
    }
  }

  static Future<void> goToShop(BuildContext context) async {
    final r = await context.read<OrdersProvider>().shopRoute();
    if (!r.ok) {
      Toast.error(r.message);
      return;
    }
    final ok = await Launcher.open(r.message);
    if (ok) {
      Toast.info('Opening route to shop');
    } else {
      Toast.error("Couldn't open Google Maps");
    }
  }
}
