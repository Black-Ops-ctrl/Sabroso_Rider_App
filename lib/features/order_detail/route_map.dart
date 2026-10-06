import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/polyline.dart';

class RouteMap extends StatelessWidget {
  const RouteMap({super.key, required this.points, required this.lineColor, required this.startColor, required this.endColor});

  final List<LatLngPoint> points;
  final Color lineColor;
  final Color startColor;
  final Color endColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RoutePainter(points: points, lineColor: lineColor, startColor: startColor, endColor: endColor),
      child: const SizedBox.expand(),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.points, required this.lineColor, required this.startColor, required this.endColor});

  final List<LatLngPoint> points;
  final Color lineColor;
  final Color startColor;
  final Color endColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFEEEBF3));
    final grid = Paint()
      ..color = Colors.white
      ..strokeWidth = 7;
    final stepX = size.width / 4;
    final stepY = size.height / 3;
    for (var i = 1; i < 4; i++) {
      final x = stepX * i + (i.isEven ? 10 : -6);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var j = 1; j < 3; j++) {
      final y = stepY * j + (j.isEven ? 8 : -4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (points.isEmpty) return;

    final lat0 = points.first.lat * math.pi / 180;
    final cosLat = math.cos(lat0).abs() < 0.01 ? 0.01 : math.cos(lat0);
    final xs = points.map((pt) => pt.lng * cosLat).toList();
    final ys = points.map((pt) => -pt.lat).toList();
    var minX = xs.reduce(math.min);
    var maxX = xs.reduce(math.max);
    var minY = ys.reduce(math.min);
    var maxY = ys.reduce(math.max);
    var spanX = maxX - minX;
    var spanY = maxY - minY;
    if (spanX < 1e-6) {
      minX -= 0.0005;
      maxX += 0.0005;
      spanX = maxX - minX;
    }
    if (spanY < 1e-6) {
      minY -= 0.0005;
      maxY += 0.0005;
      spanY = maxY - minY;
    }
    const pad = 22.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    final scale = math.min(w / spanX, h / spanY);
    final offX = pad + (w - spanX * scale) / 2;
    final offY = pad + (h - spanY * scale) / 2;
    Offset map(int i) => Offset(offX + (xs[i] - minX) * scale, offY + (ys[i] - minY) * scale);

    final path = Path()..moveTo(map(0).dx, map(0).dy);
    for (var i = 1; i < points.length; i++) {
      final o = map(i);
      path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x33000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final start = map(0);
    final end = map(points.length - 1);
    canvas.drawCircle(start, 8, Paint()..color = Colors.white);
    canvas.drawCircle(start, 5.5, Paint()..color = startColor);
    canvas.drawCircle(end, 9, Paint()..color = Colors.white);
    canvas.drawCircle(end, 6.5, Paint()..color = endColor);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.lineColor != lineColor;
}
