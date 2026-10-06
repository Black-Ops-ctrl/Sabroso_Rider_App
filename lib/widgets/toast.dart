import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/brand_provider.dart';
import '../theme/scale.dart';

enum ToastKind { success, error, info }

class _ToastData {
  const _ToastData(this.kind, this.message, this.detail, this.id);

  final ToastKind kind;
  final String message;
  final String? detail;
  final int id;
}

class Toast {
  static final GlobalKey<ToastHostState> _key = GlobalKey<ToastHostState>();
  static int _seq = 0;

  static GlobalKey<ToastHostState> get hostKey => _key;

  static void show(ToastKind kind, String message, {String? detail}) {
    if (message.isEmpty) return;
    _seq++;
    _key.currentState?._show(_ToastData(kind, message, detail, _seq));
  }

  static void success(String message, {String? detail}) => show(ToastKind.success, message, detail: detail);

  static void error(String message, {String? detail}) => show(ToastKind.error, message, detail: detail);

  static void info(String message, {String? detail}) => show(ToastKind.info, message, detail: detail);

  static void result(bool ok, String message) {
    if (ok) {
      success(message);
    } else {
      error(message);
    }
  }
}

class ToastHost extends StatefulWidget {
  const ToastHost({super.key});

  @override
  State<ToastHost> createState() => ToastHostState();
}

class ToastHostState extends State<ToastHost> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));
  _ToastData? _data;

  void _show(_ToastData d) {
    if (!mounted) return;
    setState(() => _data = d);
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _seg(double t, double a, double b) {
    if (t <= a) return 0;
    if (t >= b) return 1;
    return (t - a) / (b - a);
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    if (d == null) return const SizedBox.shrink();
    final colors = context.watch<BrandProvider>().colors;
    final Color tone;
    final Widget glyph;
    final iconSize = context.sp(30);
    switch (d.kind) {
      case ToastKind.success:
        tone = colors.success;
        glyph = Icon(Icons.check_rounded, color: Colors.white, size: iconSize * 0.62);
        break;
      case ToastKind.error:
        tone = colors.error;
        glyph = Icon(Icons.priority_high_rounded, color: Colors.white, size: iconSize * 0.58);
        break;
      case ToastKind.info:
        tone = colors.info;
        glyph = Text('i', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: iconSize * 0.5, height: 1));
        break;
    }
    final maxWidth = MediaQuery.sizeOf(context).width - context.sp(32);
    return Positioned(
      top: context.topInset + context.sp(8),
      left: 0,
      right: 0,
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            if (t >= 1 || !_c.isAnimating && t == 0) return const SizedBox.shrink();
            final drop = Curves.easeOutBack.transform(_seg(t, 0, 0.1));
            final open = Curves.easeOutCubic.transform(_seg(t, 0.08, 0.2));
            final close = Curves.easeInCubic.transform(_seg(t, 0.84, 0.93));
            final leave = Curves.easeInCubic.transform(_seg(t, 0.92, 1));
            final width = (open * (1 - close)).clamp(0.0, 1.0);
            final dy = -context.sp(24) * (1 - drop) - context.sp(28) * leave;
            final opacity = (drop.clamp(0.0, 1.0) * (1 - leave)).clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(0, dy),
              child: Opacity(
                opacity: opacity,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      if (_c.value < 0.84) {
                        _c.value = 0.84;
                        _c.forward();
                      }
                    },
                    child: Container(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      padding: EdgeInsets.all(context.sp(5)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(color: Color(0x241C1726), blurRadius: 24, offset: Offset(0, 10)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: iconSize,
                            height: iconSize,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
                            child: glyph,
                          ),
                          Flexible(
                            child: ClipRect(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                widthFactor: width,
                                child: Padding(
                                  padding: EdgeInsets.only(left: context.sp(10), right: context.sp(14)),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        d.message,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colors.text,
                                          fontSize: context.sp(13),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (d.detail != null && d.detail!.isNotEmpty)
                                        Text(
                                          d.detail!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: colors.muted, fontSize: context.sp(11.5)),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
