import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api.dart';
import 'core/store.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/session_provider.dart';
import 'features/history/history_provider.dart';
import 'features/home/home_provider.dart';
import 'features/orders/duty_provider.dart';
import 'features/orders/orders_provider.dart';
import 'features/settings/notifications_provider.dart';
import 'features/shell/shell_controller.dart';
import 'features/splash/splash_screen.dart';
import 'theme/brand_provider.dart';
import 'widgets/routes.dart';
import 'widgets/toast.dart';

class RiderApp extends StatefulWidget {
  const RiderApp({super.key, required this.store});

  final Store store;

  @override
  State<RiderApp> createState() => _RiderAppState();
}

class _RiderAppState extends State<RiderApp> {
  late final Api api = Api(token: widget.store.token);
  late final BrandProvider brand = BrandProvider(api, widget.store);
  late final SessionProvider session = SessionProvider(api, widget.store);
  late final DutyProvider duty = DutyProvider(api, session);
  late final OrdersProvider orders = OrdersProvider(api);
  late final HomeProvider home = HomeProvider(api);
  late final HistoryProvider history = HistoryProvider(api);
  late final NotificationsProvider notifications = NotificationsProvider(api, session);
  late final ShellController shell = ShellController();
  StreamSubscription<Set<String>>? _sub;

  @override
  void initState() {
    super.initState();
    orders.onNotice = (message, detail) => Toast.info(message, detail: detail);
    session.onCleared = () {
      orders.reset();
      home.reset();
      history.reset();
      notifications.reset();
      shell.reset();
    };
    session.onSignedOut = () {
      Nav.replaceAll(const LoginScreen());
      Future<void>.delayed(const Duration(milliseconds: 350), () => Toast.info('You have been logged out'));
    };
    _sub = session.changes.listen(_onChange);
  }

  void _onChange(Set<String> tables) {
    final all = tables.contains('*');
    bool has(List<String> names) => all || names.any(tables.contains);
    if (has(const <String>['app_settings', 'companies'])) brand.load();
    if (has(const <String>['orders', 'order_items', 'customers', 'shops', 'lookups'])) {
      if (orders.loaded) orders.load(silent: true);
      if (history.hasResult) history.refresh(silent: true);
    }
    if (has(const <String>['orders', 'riders', 'rider_duty_sessions'])) {
      if (home.loaded) home.load(silent: true);
    }
    if (has(const <String>['rider_notifications'])) {
      if (notifications.loaded) notifications.load(silent: true);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BrandProvider>.value(value: brand),
        ChangeNotifierProvider<SessionProvider>.value(value: session),
        ChangeNotifierProvider<DutyProvider>.value(value: duty),
        ChangeNotifierProvider<OrdersProvider>.value(value: orders),
        ChangeNotifierProvider<HomeProvider>.value(value: home),
        ChangeNotifierProvider<HistoryProvider>.value(value: history),
        ChangeNotifierProvider<NotificationsProvider>.value(value: notifications),
        ChangeNotifierProvider<ShellController>.value(value: shell),
      ],
      child: Consumer<BrandProvider>(
        builder: (context, b, _) {
          final p = b.colors;
          return MaterialApp(
            title: 'Sabroso Rider',
            debugShowCheckedModeBanner: false,
            navigatorKey: Nav.key,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: p.accent, primary: p.accent, surface: p.card),
              scaffoldBackgroundColor: p.background,
              splashFactory: InkRipple.splashFactory,
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: p.accent,
                selectionColor: p.accent.withAlpha(60),
                selectionHandleColor: p.accent,
              ),
              progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
            ),
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.15)),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    child ?? const SizedBox.shrink(),
                    ToastHost(key: Toast.hostKey),
                  ],
                ),
              );
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
