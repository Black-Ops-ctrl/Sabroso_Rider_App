import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../theme/brand_provider.dart';
import '../../theme/scale.dart';
import '../../widgets/routes.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';
import '../auth/login_screen.dart';
import '../auth/session_provider.dart';
import '../shell/app_flow.dart';
import 'bike_svg.dart';

const Color _kInk = Color(0xFF1C1726);
const Color _kPurple = Color(0xFF6D28D9);
const Color _kDeep = Color(0xFF4C1D95);
const Color _kLight = Color(0xFFA855F7);
const Color _kBg = Color(0xFFF6F4F1);

double _clamp01(double x) => x < 0 ? 0 : (x > 1 ? 1 : x);
double _easeOut(double x) {
  final v = _clamp01(x);
  return 1 - math.pow(1 - v, 3).toDouble();
}

double _easeInOut(double x) {
  final v = _clamp01(x);
  return v < 0.5 ? 4 * v * v * v : 1 - math.pow(-2 * v + 2, 3).toDouble() / 2;
}

class _Geo {
  _Geo(this.size)
      : k = math.max(0.01, math.min(size.width / 340, size.height / 720)),
        cy = size.height * 0.42 {
    route = Path()
      ..moveTo(mapX(46), mapY(610))
      ..cubicTo(mapX(46), mapY(520), mapX(120), mapY(520), mapX(110), mapY(460))
      ..cubicTo(mapX(100), mapY(400), mapX(60), mapY(420), mapX(80.8), mapY(399.2));
    metric = route.computeMetrics().first;
  }

  final Size size;
  final double k;
  final double cy;
  late final Path route;
  late final ui.PathMetric metric;

  double mapX(double x) => size.width / 2 + (x - 160) * k;
  double mapY(double y) => cy + (y - 320) * k;
  Offset get center => Offset(size.width / 2, cy);
  double get radius => 112 * k;
  Offset get start => Offset(mapX(46), mapY(610));

  static const double a0 = math.pi * 0.75;

  double orbitAngle(double t) {
    final u = _easeInOut((t - 0.34) / 0.52);
    return a0 + u * (math.pi * 2 - a0 + math.pi * 1.5);
  }
}

class _Pose {
  const _Pose(this.position, this.flip, this.tilt);

  final Offset position;
  final bool flip;
  final double tilt;
}

_Pose _poseAt(_Geo g, double t) {
  if (t < 0.34) {
    final q = _easeInOut(t / 0.34);
    final len = g.metric.length;
    final tan = g.metric.getTangentForOffset(len * q);
    final next = g.metric.getTangentForOffset(math.min(len, len * q + 2));
    final pos = tan?.position ?? g.start;
    final ahead = next?.position ?? pos;
    final dx = ahead.dx - pos.dx;
    final dy = ahead.dy - pos.dy;
    final tilt = (math.atan2(dy, dx.abs()) * 0.3).clamp(-0.21, 0.21).toDouble();
    return _Pose(pos, dx < 0, tilt);
  }
  final a = g.orbitAngle(t);
  final pos = g.center + Offset(math.cos(a), math.sin(a)) * g.radius;
  return _Pose(pos, math.sin(a) > 0, 0);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400));
  late final AnimationController _dots = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  final Completer<void> _animDone = Completer<void>();

  @override
  void initState() {
    super.initState();
    _anim.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_animDone.isCompleted) _animDone.complete();
    });
    _anim.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final brand = context.read<BrandProvider>();
    final session = context.read<SessionProvider>();
    final brandLoad = brand.load().timeout(const Duration(seconds: 8), onTimeout: () {});
    final result = await session.restore();
    await brandLoad;
    await _animDone.future;
    if (!mounted) return;
    if (result == RestoreResult.none) {
      Nav.replaceAll(const LoginScreen());
      return;
    }
    await AppFlow.enter();
    final err = session.restoreError;
    if (result == RestoreResult.offline && err != null) {
      Future<void>.delayed(const Duration(milliseconds: 400), () => Toast.error(err));
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: kDarkBar,
      child: Scaffold(
        backgroundColor: _kBg,
        body: LayoutBuilder(
          builder: (context, box) {
            final g = _Geo(Size(box.maxWidth, box.maxHeight));
            final k = g.k;
            return AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[_anim, _dots]),
              builder: (context, _) {
                final t = _anim.value;
                final bout = _easeOut((t - 0.86) / 0.06);
                final tq = _easeOut((t - 0.22) / 0.22);
                final q3 = _easeOut((t - 0.5) / 0.18);
                final dq = _easeOut((t - 0.55) / 0.1);
                final pose = _poseAt(g, t);
                final tile = 130 * k;
                final bikeW = 64 * k;
                final bikeH = 42 * k;
                return Stack(
                  children: <Widget>[
                    Positioned.fill(child: CustomPaint(painter: _SplashPainter(g, t))),
                    Positioned(
                      left: g.center.dx - tile / 2,
                      top: g.center.dy - tile / 2,
                      width: tile,
                      height: tile,
                      child: Opacity(
                        opacity: tq,
                        child: Transform.scale(
                          scale: 0.5 + 0.5 * tq,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: <Color>[_kDeep, _kPurple],
                              ),
                              boxShadow: <BoxShadow>[BoxShadow(color: Color(0x403B0764), blurRadius: 36, offset: Offset(0, 18))],
                            ),
                            alignment: Alignment.center,
                            child: BrandLogo(height: tile * 0.42, maxWidth: tile * 0.78),
                          ),
                        ),
                      ),
                    ),
                    if (bout < 1)
                      Positioned(
                        left: pose.position.dx - bikeW / 2,
                        top: pose.position.dy - bikeH * 0.9,
                        width: bikeW,
                        height: bikeH,
                        child: Opacity(
                          opacity: 1 - bout,
                          child: Transform.rotate(
                            angle: pose.tilt,
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.diagonal3Values(pose.flip ? -1 : 1, 1, 1),
                              child: SvgPicture.string(kBikeSvg, width: bikeW, height: bikeH, fit: BoxFit.contain),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: g.center.dy + 150 * k,
                      child: Opacity(
                        opacity: q3,
                        child: Transform.translate(
                          offset: Offset(0, 14 * k * (1 - q3)),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24 * k),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text.rich(
                                TextSpan(
                                  children: const <InlineSpan>[
                                    TextSpan(text: 'Sabroso ', style: TextStyle(fontWeight: FontWeight.w300)),
                                    TextSpan(text: 'Rider App', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ],
                                  style: TextStyle(color: _kInk, fontSize: 25 * k, letterSpacing: 0.2),
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: context.bottomInset + box.maxHeight * 0.1,
                      child: Opacity(opacity: dq, child: _Dots(phase: _dots.value, k: k)),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.phase, required this.k});

  final double phase;
  final double k;

  @override
  Widget build(BuildContext context) {
    final size = 7 * k;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(3, (i) {
        final s = math.sin(phase * math.pi * 2 - i * 1.1);
        final lift = -5 * k * math.max(0, s);
        final opacity = (0.35 + 0.65 * (0.5 + 0.5 * s)).clamp(0.0, 1.0).toDouble();
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.5 * k),
          child: Transform.translate(
            offset: Offset(0, lift),
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(color: _kPurple, shape: BoxShape.circle),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SplashPainter extends CustomPainter {
  _SplashPainter(this.g, this.t);

  final _Geo g;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final k = g.k;
    final bout = _easeOut((t - 0.86) / 0.06);
    final fq = _easeOut((t - 0.4) / 0.14);
    final hq = _easeOut((t - 0.2) / 0.3);
    final center = g.center;

    if (hq > 0) {
      final r = 180 * k * hq;
      final halo = Paint()
        ..shader = const RadialGradient(colors: <Color>[Color(0xFFEDE9FE), Color(0x00EDE9FE)], stops: <double>[0, 0.7])
            .createShader(Rect.fromCircle(center: center, radius: r));
      canvas.drawCircle(center, r, halo);
    }

    final orbOpacity = _easeOut((t - 0.3) / 0.1) * (1 - bout * 0.6);
    if (orbOpacity > 0) {
      final paint = Paint()
        ..color = const Color(0xFFDDD6FE).withAlpha((255 * orbOpacity).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * k
        ..strokeCap = StrokeCap.round;
      final rect = Rect.fromCircle(center: center, radius: g.radius);
      final circumference = 2 * math.pi * g.radius;
      final step = 12 * k;
      final count = (circumference / step).floor();
      final dash = (3 * k) / g.radius;
      for (var i = 0; i < count; i++) {
        canvas.drawArc(rect, i * (2 * math.pi / count), dash, false, paint);
      }
    }

    final routeOpacity = 1 - fq;
    if (routeOpacity > 0) {
      final len = g.metric.length;
      final base = Paint()..color = const Color(0xFFE4DDF2).withAlpha((255 * routeOpacity).round());
      for (double d = 0; d <= len; d += 14 * k) {
        final tan = g.metric.getTangentForOffset(d);
        if (tan != null) canvas.drawCircle(tan.position, 3 * k, base);
      }
      final q1 = _easeInOut(t / 0.34);
      if (q1 > 0) {
        final part = g.metric.extractPath(0, len * q1);
        final bounds = g.route.getBounds();
        final line = Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: <Color>[
              _kDeep.withAlpha((255 * routeOpacity).round()),
              _kLight.withAlpha((255 * routeOpacity).round()),
            ],
          ).createShader(bounds)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6 * k
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(part, line);
      }
      final startFill = Paint()..color = Colors.white.withAlpha((255 * routeOpacity).round());
      final startRing = Paint()
        ..color = _kPurple.withAlpha((255 * routeOpacity).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * k;
      canvas.drawCircle(g.start, 9 * k, startFill);
      canvas.drawCircle(g.start, 9 * k, startRing);
    }

    if (t >= 0.34 && bout < 1) {
      final a = g.orbitAngle(t);
      final aS = math.max(_Geo.a0, a - 1.3);
      final sweep = a - aS;
      if (sweep > 0.001) {
        final rect = Rect.fromCircle(center: center, radius: g.radius);
        const parts = 14;
        for (var i = 0; i < parts; i++) {
          final f = (i + 1) / parts;
          final paint = Paint()
            ..color = Color.lerp(_kLight, _kPurple, f)!.withAlpha((255 * f * (1 - bout)).round())
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5 * k
            ..strokeCap = StrokeCap.round;
          canvas.drawArc(rect, aS + sweep * i / parts, sweep / parts, false, paint);
        }
      }
    }

    final pq = _easeOut((t - 0.84) / 0.08);
    if (pq > 0) {
      final ox = g.mapX(148);
      final oy = g.mapY(176) - 14 * k * (1 - pq);
      double px(double x) => ox + x * k;
      double py(double y) => oy + y * k;
      final pin = Path()
        ..moveTo(px(12), py(0))
        ..cubicTo(px(5), py(0), px(0), py(5), px(0), py(12))
        ..cubicTo(px(0), py(21), px(12), py(32), px(12), py(32))
        ..cubicTo(px(12), py(32), px(24), py(21), px(24), py(12))
        ..cubicTo(px(24), py(5), px(19), py(0), px(12), py(0))
        ..close();
      canvas.drawPath(pin, Paint()..color = _kPurple.withAlpha((255 * pq).round()));
      canvas.drawCircle(Offset(px(12), py(12)), 5 * k, Paint()..color = Colors.white.withAlpha((255 * pq).round()));
    }
  }

  @override
  bool shouldRepaint(covariant _SplashPainter oldDelegate) => oldDelegate.t != t || oldDelegate.g.size != g.size;
}
