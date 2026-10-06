import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/store.dart';
import 'theme/scale.dart';
import 'tracking/location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(kDarkBar);
  final store = await Store.open();
  try {
    await LocationService.instance.configure(onBoot: store.onDuty);
  } catch (_) {}
  runApp(RiderApp(store: store));
}
