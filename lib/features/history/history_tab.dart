import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/scale.dart';
import '../../widgets/routes.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';
import '../order_detail/order_detail_screen.dart';
import '../shell/floating_nav.dart';
import '../shell/shell_screen.dart';
import 'history_provider.dart';
import 'range_picker_sheet.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  Future<void> _pick() async {
    final h = context.read<HistoryProvider>();
    final r = await RangePickerSheet.show(context, start: h.from, end: h.to);
    if (r != null) h.setRange(r.start, r.end);
  }

  Future<void> _show() async {
    final r = await context.read<HistoryProvider>().show();
    if (!r.ok && r.message.isNotEmpty) Toast.error(r.message);
  }

  Future<void> _refresh() async {
    final h = context.read<HistoryProvider>();
    if (!h.searched) return;
    await h.refresh();
    final err = h.error;
    if (err != null) Toast.error(err);
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 240) {
      final h = context.read<HistoryProvider>();
      if (h.hasMore && !h.loadingMore && !h.loading) {
        h.loadMore().then((r) {
          if (!r.ok && r.message.isNotEmpty) Toast.error(r.message);
        });
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final h = context.watch<HistoryProvider>();
    return Column(
      children: <Widget>[
        TabHeader(
          tab: 2,
          child: Text(
            'Order History',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontSize: context.sp(24), fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: p.accent,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(context.sp(16), context.sp(16), context.sp(16), navReserve(context)),
                children: <Widget>[
                  Stagger(index: 0, child: _RangeCard(onPick: _pick, onShow: _show)),
                  SizedBox(height: context.sp(18)),
                  ..._results(context, h),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _results(BuildContext context, HistoryProvider h) {
    if (!h.searched) {
      return const <Widget>[EmptyState(icon: Icons.calendar_month_outlined, text: 'Select a date range')];
    }
    if (h.loading && !h.hasResult) return const <Widget>[LoadingBlock()];
    if (!h.hasResult && h.error != null) {
      return <Widget>[
        EmptyState(
          icon: Icons.cloud_off_rounded,
          text: h.error!,
          action: TextButton(onPressed: _show, child: const Text('Try again')),
        ),
      ];
    }
    final out = <Widget>[
      Stagger(index: 1, child: _SummaryCard(summary: h.summary)),
      SizedBox(height: context.sp(18)),
    ];
    if (h.rows.isEmpty) {
      out.add(const EmptyState(icon: Icons.receipt_long_outlined, text: 'No orders in this range'));
      return out;
    }
    final groups = <DateTime, List<RiderOrder>>{};
    for (final o in h.rows) {
      final d = o.finishedAt ?? DateTime.now();
      final key = DateTime(d.year, d.month, d.day);
      groups.putIfAbsent(key, () => <RiderOrder>[]).add(o);
    }
    final now = DateTime.now();
    var i = 2;
    groups.forEach((day, list) {
      final label = Fmt.sameDay(day, now) ? 'Today · ${Fmt.dayMonthUpper(day)}' : Fmt.dayMonthUpper(day);
      out.add(SectionLabel(label, trailing: '${list.length} ${list.length == 1 ? 'order' : 'orders'}'));
      for (final o in list) {
        out.add(
          Padding(
            key: ValueKey<String>('h${o.id}'),
            padding: EdgeInsets.only(bottom: context.sp(10)),
            child: Stagger(index: i++, child: _HistoryRow(order: o)),
          ),
        );
      }
      out.add(SizedBox(height: context.sp(6)));
    });
    if (h.loadingMore) out.add(const LoadingBlock());
    return out;
  }
}

class _RangeCard extends StatelessWidget {
  const _RangeCard({required this.onPick, required this.onShow});

  final VoidCallback onPick;
  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final h = context.watch<HistoryProvider>();
    return AppCard(
      padding: EdgeInsets.fromLTRB(context.sp(18), context.sp(16), context.sp(18), context.sp(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _DateField(label: 'FROM', value: h.from, onTap: onPick)),
              SizedBox(width: context.sp(18)),
              Expanded(child: _DateField(label: 'TO', value: h.to, onTap: onPick)),
            ],
          ),
          SizedBox(height: context.sp(18)),
          GradientButton(
            label: 'Show orders',
            icon: Icons.search_rounded,
            gradient: h.canSearch
                ? p.accentButton
                : const LinearGradient(colors: <Color>[Color(0xFFE9E3F5), Color(0xFFE9E3F5)]),
            textColor: h.canSearch ? Colors.white : const Color(0xFF9D95B0),
            busy: h.loading,
            onTap: h.canSearch ? onShow : null,
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap});

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final v = value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.sp(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: TextStyle(color: p.muted, fontSize: context.sp(11), letterSpacing: 2)),
          SizedBox(height: context.sp(6)),
          Row(
            children: <Widget>[
              Icon(Icons.calendar_today_outlined, size: context.sp(15), color: v == null ? p.muted : p.accent),
              SizedBox(width: context.sp(8)),
              Expanded(
                child: Text(
                  v == null ? 'Select date' : Fmt.date(v),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: v == null ? const Color(0xFFB3ADBF) : p.text, fontSize: context.sp(14)),
                ),
              ),
            ],
          ),
          SizedBox(height: context.sp(8)),
          Container(height: v == null ? 1.0 : 1.5, color: v == null ? AppColors.border : p.accent),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final HistorySummary summary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      padding: EdgeInsets.symmetric(vertical: context.sp(14), horizontal: context.sp(6)),
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            Expanded(child: _Stat(value: '${summary.delivered}', label: 'Delivered', color: AppColors.delivered)),
            const _VDivider(),
            Expanded(child: _Stat(value: '${summary.cancelled}', label: 'Cancelled', color: p.cancel)),
            const _VDivider(),
            Expanded(child: _Stat(value: Fmt.km(summary.km), label: 'Distance', color: p.text)),
            const _VDivider(),
            Expanded(child: _Stat(value: Fmt.minutes(summary.avgDeliveryMin), label: 'Avg.', color: p.text)),
          ],
        ),
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider();

  @override
  Widget build(BuildContext context) => Container(width: 1, margin: EdgeInsets.symmetric(vertical: context.sp(4)), color: AppColors.border);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.sp(3)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, maxLines: 1, style: TextStyle(color: color, fontSize: context.sp(16.5), fontWeight: FontWeight.w700)),
          ),
          SizedBox(height: context.sp(2)),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: context.sp(11))),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.order});

  final RiderOrder order;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final o = order;
    return AppCard(
      padding: EdgeInsets.fromLTRB(context.sp(16), context.sp(13), context.sp(10), context.sp(13)),
      onTap: () => Nav.push<void>(OrderDetailScreen(orderId: o.id, code: o.code)),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        o.code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.text, fontSize: context.sp(14.5), fontWeight: FontWeight.w700),
                      ),
                    ),
                    SizedBox(width: context.sp(8)),
                    Flexible(
                      child: StatusChip(status: o.status, label: o.statusLabel.isEmpty ? Fmt.titleCase(o.status) : o.statusLabel),
                    ),
                  ],
                ),
                SizedBox(height: context.sp(4)),
                Text(
                  '${o.customer.name} · ${Fmt.time(o.finishedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.muted, fontSize: context.sp(12.5)),
                ),
              ],
            ),
          ),
          SizedBox(width: context.sp(8)),
          Text(Fmt.money(o.total), style: TextStyle(color: p.text, fontSize: context.sp(14), fontWeight: FontWeight.w700)),
          Icon(Icons.chevron_right_rounded, color: p.muted, size: context.sp(20)),
        ],
      ),
    );
  }
}
