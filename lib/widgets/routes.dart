import 'package:flutter/material.dart';

class SlideFadeRoute<T> extends PageRouteBuilder<T> {
  SlideFadeRoute(Widget page)
      : super(
          transitionDuration: const Duration(milliseconds: 480),
          reverseTransitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (context, animation, secondary) => page,
          transitionsBuilder: (context, animation, secondary, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
            final back = CurvedAnimation(parent: secondary, curve: Curves.easeOutCubic);
            return SlideTransition(
              position: Tween<Offset>(begin: Offset.zero, end: const Offset(-0.18, 0)).animate(back),
              child: FadeTransition(
                opacity: Tween<double>(begin: 1, end: 0.6).animate(back),
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.35, 0), end: Offset.zero).animate(curved),
                  child: FadeTransition(opacity: curved, child: child),
                ),
              ),
            );
          },
        );
}

class FadeRoute<T> extends PageRouteBuilder<T> {
  FadeRoute(Widget page)
      : super(
          transitionDuration: const Duration(milliseconds: 520),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondary) => page,
          transitionsBuilder: (context, animation, secondary, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(scale: Tween<double>(begin: 0.97, end: 1).animate(curved), child: child),
            );
          },
        );
}

class Nav {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static Future<T?> push<T>(Widget page) {
    final nav = key.currentState;
    if (nav == null) return Future<T?>.value(null);
    return nav.push<T>(SlideFadeRoute<T>(page));
  }

  static void replaceAll(Widget page) {
    final nav = key.currentState;
    if (nav == null) return;
    nav.pushAndRemoveUntil<void>(FadeRoute<void>(page), (route) => false);
  }
}
