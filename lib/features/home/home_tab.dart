import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/scale.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';
import '../auth/session_provider.dart';
import '../orders/orders_provider.dart';
import '../shell/floating_nav.dart';
import '../shell/shell_controller.dart';
import '../shell/shell_screen.dart';
import 'home_provider.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final home = context.read<HomeProvider>();
      home.load(silent: home.loaded);
    });
  }

  Future<void> _refresh() async {
    final home = context.read<HomeProvider>();
    final session = context.read<SessionProvider>();
    await Future.wait(<Future<void>>[home.load(silent: true), session.refreshMe()]);
    final err = home.error;
    if (err != null) Toast.error(err);
  }

  void _openOrders(String filter) {
    context.read<OrdersProvider>().setFilter(filter);
    context.read<ShellController>().go(1);
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final rider = context.watch<SessionProvider>().rider;
    final stats = home.stats;
    return Column(
      children: <Widget>[
        TabHeader(tab: 0, child: _HomeHeader(name: rider?.name ?? '', shop: rider?.shop?.name ?? '')),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: context.palette.accent,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(context.sp(16), context.sp(16), context.sp(16), navReserve(context)),
              children: <Widget>[
                if (stats == null && home.loading) const LoadingBlock(),
                if (stats == null && !home.loading && home.error != null)
                  EmptyState(
                    icon: Icons.cloud_off_rounded,
                    text: home.error!,
                    action: TextButton(onPressed: () => home.load(), child: const Text('Try again')),
                  ),
                if (stats != null) ...<Widget>[
                  Stagger(index: 0, child: _SummaryCard(stats: stats, onRow: _openOrders)),
                  SizedBox(height: context.sp(14)),
                  Stagger(index: 1, child: _NumbersCard(stats: stats)),
                  SizedBox(height: context.sp(14)),
                  Stagger(index: 2, child: _WeekCard(stats: stats)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.name, required this.shop});

  final String name;
  final String shop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: BrandLogo(height: context.sp(40), maxWidth: context.sp(150)),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: context.sp(14), vertical: context.sp(6)),
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0x59FFFFFF)),
              ),
              child: Text(
                'TODAY',
                style: TextStyle(color: const Color(0xE6FFFFFF), fontSize: context.sp(11), letterSpacing: 2.4, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        SizedBox(height: context.sp(18)),
        Text(
          Fmt.greeting(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: const Color(0xD9FFFFFF), fontSize: context.sp(14), letterSpacing: 0.3),
        ),
        SizedBox(height: context.sp(2)),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white, fontSize: context.sp(22), fontWeight: FontWeight.w700),
        ),
        if (shop.isNotEmpty) ...<Widget>[
          SizedBox(height: context.sp(4)),
          Row(
            children: <Widget>[
              Icon(Icons.storefront_outlined, color: const Color(0xE6FFFFFF), size: context.sp(16)),
              SizedBox(width: context.sp(8)),
              Flexible(
                child: Text(
                  shop,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: const Color(0xE6FFFFFF), fontSize: context.sp(13.5)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.stats, required this.onRow});

  final HomeStats stats;
  final ValueChanged<String> onRow;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = stats.counts;
    final total = c.all;
    final ring = context.sp(104);
    return AppCard(
      padding: EdgeInsets.fromLTRB(context.sp(16), context.sp(18), context.sp(10), context.sp(18)),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: ring,
            height: ring,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: total == 0 ? 0 : c.delivered / total),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, child) => CustomPaint(
                painter: _RingPainter(progress: v, color: p.ring, stroke: context.sp(10)),
                child: child,
              ),
              child: Padding(
                padding: EdgeInsets.all(context.sp(18)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '${c.delivered}/$total',
                        style: TextStyle(color: p.text, fontSize: context.sp(22), fontWeight: FontWeight.w700),
                      ),
                      Text('delivered', style: TextStyle(color: p.muted, fontSize: context.sp(10.5))),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: context.sp(12)),
          Expanded(
            child: Column(
              children: <Widget>[
                _CountRow(label: 'Assigned', count: c.assigned, color: AppColors.assigned, onTap: () => onRow(OrderStatus.assigned)),
                _CountRow(label: 'Out for delivery', count: c.outForDelivery, color: AppColors.ofd, onTap: () => onRow(OrderStatus.outForDelivery)),
                _CountRow(label: 'Delivered', count: c.delivered, color: AppColors.delivered, onTap: () => onRow(OrderStatus.delivered)),
                _CountRow(label: 'Cancelled', count: c.cancelled, color: p.cancel, onTap: () => onRow(OrderStatus.cancelled)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({required this.label, required this.count, required this.color, required this.onTap});

  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(context.sp(10)),
        splashColor: fade(p.accent, 0.12),
        highlightColor: fade(p.accent, 0.06),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.sp(6), vertical: context.sp(7)),
          child: Row(
            children: <Widget>[
              Container(
                width: context.sp(9),
                height: context.sp(9),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: context.sp(10)),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.text2, fontSize: context.sp(13.5)),
                ),
              ),
              SizedBox(width: context.sp(6)),
              Text('$count', style: TextStyle(color: p.text, fontSize: context.sp(14), fontWeight: FontWeight.w700)),
              SizedBox(width: context.sp(4)),
              Icon(Icons.chevron_right_rounded, size: context.sp(18), color: p.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color, required this.stroke});

  final double progress;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2 - stroke / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: r);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = const Color(0xFFEFEAF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.stroke != stroke;
}

class _NumbersCard extends StatelessWidget {
  const _NumbersCard({required this.stats});

  final HomeStats stats;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.symmetric(vertical: context.sp(16), horizontal: context.sp(8)),
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            Expanded(child: _Number(value: Fmt.km(stats.distanceKm), label: 'Distance')),
            const _Divider(),
            Expanded(child: _Number(value: Fmt.minutes(stats.avgDeliveryMin), label: 'Avg. delivery')),
            const _Divider(),
            Expanded(child: _Number(value: Fmt.duration(stats.onDutyMin), label: 'On duty')),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, margin: EdgeInsets.symmetric(vertical: context.sp(4)), color: AppColors.border);
  }
}

class _Number extends StatelessWidget {
  const _Number({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.sp(4)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, maxLines: 1, style: TextStyle(color: p.text, fontSize: context.sp(18), fontWeight: FontWeight.w700)),
          ),
          SizedBox(height: context.sp(3)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: p.muted, fontSize: context.sp(11.5)),
          ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.stats});

  final HomeStats stats;

  static const List<String> _letters = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final week = stats.week;
    final today = Fmt.parseYmd(stats.today);
    var max = 1;
    for (final d in week) {
      if (d.delivered > max) max = d.delivered;
    }
    return AppCard(
      padding: EdgeInsets.fromLTRB(context.sp(18), context.sp(16), context.sp(18), context.sp(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'This week',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.text, fontSize: context.sp(14.5), fontWeight: FontWeight.w700),
                ),
              ),
              Text('${stats.weekTotal} delivered', style: TextStyle(color: p.muted, fontSize: context.sp(13))),
            ],
          ),
          SizedBox(height: context.sp(14)),
          SizedBox(
            height: context.sp(110),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List<Widget>.generate(7, (i) {
                final day = i < week.length ? week[i] : null;
                final date = day == null ? null : Fmt.parseYmd(day.day);
                final isToday = date != null && today != null && Fmt.sameDay(date, today);
                final future = date != null && today != null && date.isAfter(today);
                final value = day?.delivered ?? 0;
                return Expanded(
                  child: _Bar(
                    letter: _letters[i],
                    fraction: value / max,
                    today: isToday,
                    empty: future || value == 0,
                    count: value,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.letter, required this.fraction, required this.today, required this.empty, required this.count});

  final String letter;
  final double fraction;
  final bool today;
  final bool empty;
  final int count;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final w = context.sp(20);
    return Column(
      children: <Widget>[
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final full = box.maxHeight;
              final h = empty ? context.sp(6) : math.max(context.sp(10), full * fraction.clamp(0.0, 1.0));
              return Align(
                alignment: Alignment.bottomCenter,
                child: Tooltip(
                  message: '$count',
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: math.min(h, full)),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Container(
                      width: empty ? w * 1.1 : w,
                      height: v,
                      decoration: BoxDecoration(
                        color: empty ? const Color(0xFFEBE7F1) : (today ? null : const Color(0xFFE4DCF5)),
                        gradient: !empty && today
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[p.chartBar, Color.lerp(p.chartBar, Colors.black, 0.25)!],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: context.sp(8)),
        Text(
          letter,
          style: TextStyle(
            color: today ? p.accent : p.muted,
            fontSize: context.sp(11.5),
            fontWeight: today ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
