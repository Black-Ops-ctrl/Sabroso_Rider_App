import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../theme/scale.dart';
import '../../widgets/measure_size.dart';
import '../../widgets/toast.dart';
import '../auth/session_provider.dart';
import '../history/history_tab.dart';
import '../home/home_tab.dart';
import '../orders/orders_provider.dart';
import '../orders/orders_tab.dart';
import '../settings/settings_tab.dart';
import 'floating_nav.dart';
import 'shell_controller.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  DateTime? _lastBack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final orders = context.read<OrdersProvider>();
      if (!orders.loaded) orders.load(silent: true);
    });
  }

  void _onBack(ShellController shell) {
    if (shell.index != 0) {
      shell.go(0);
      return;
    }
    final now = DateTime.now();
    final last = _lastBack;
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      }
      return;
    }
    _lastBack = now;
    Toast.info('Press back again to exit');
  }

  Widget _page(int i) {
    switch (i) {
      case 1:
        return const OrdersTab();
      case 2:
        return const HistoryTab();
      case 3:
        return const SettingsTab();
      default:
        return const HomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shell = context.watch<ShellController>();
    final orders = context.watch<OrdersProvider>();
    final session = context.watch<SessionProvider>();
    final badge = orders.loaded ? orders.activeCount : (session.rider?.openOrders ?? 0);
    final forward = shell.index >= shell.previous;
    final headerH = shell.headerHeight(shell.index) ?? (context.topInset + context.sp(120));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: kLightBar,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _onBack(shell);
        },
        child: Scaffold(
          backgroundColor: p.background,
          resizeToAvoidBottomInset: false,
          body: SizedBox.expand(
            child: Stack(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                height: headerH,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: p.header,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(context.sp(28))),
                ),
              ),
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (current, previous) => Stack(
                    fit: StackFit.expand,
                    children: <Widget>[...previous, if (current != null) current],
                  ),
                  transitionBuilder: (child, animation) {
                    final incoming = child.key == ValueKey<int>(shell.index);
                    final dir = forward ? 1.0 : -1.0;
                    final begin = incoming ? Offset(0.22 * dir, 0) : Offset(-0.22 * dir, 0);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(key: ValueKey<int>(shell.index), child: _page(shell.index)),
                ),
              ),
              Positioned(
                left: context.sp(16),
                right: context.sp(16),
                bottom: context.bottomInset + context.sp(14),
                child: FloatingNav(index: shell.index, badge: badge, onTap: shell.go),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class TabHeader extends StatelessWidget {
  const TabHeader({super.key, required this.tab, required this.child});

  final int tab;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shell = context.read<ShellController>();
    return MeasureSize(
      onChange: (size) => shell.setHeader(tab, size.height),
      child: Padding(
        padding: EdgeInsets.fromLTRB(context.sp(22), context.topInset + context.sp(16), context.sp(20), context.sp(24)),
        child: child,
      ),
    );
  }
}