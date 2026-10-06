import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/polyline.dart';
import '../../theme/app_colors.dart';
import '../../theme/scale.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';
import '../auth/session_provider.dart';
import '../orders/order_actions.dart';
import '../orders/widgets/order_card.dart';
import 'route_map.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId, this.code = ''});

  final int orderId;
  final String code;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  RiderOrder? _order;
  String? _error;
  bool _loading = true;
  StreamSubscription<Set<String>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = context.read<SessionProvider>().changes.listen((tables) {
      if (tables.contains('*') || tables.contains('orders') || tables.contains('order_items') || tables.contains('customers')) {
        _load(silent: true);
      }
    });
    _load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    final api = context.read<SessionProvider>().api;
    if (!silent && mounted) setState(() => _loading = _order == null);
    try {
      final o = RiderOrder.fromJson(await api.get('/rider/orders/${widget.orderId}'));
      if (!mounted) return;
      setState(() {
        _order = o;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
      if (silent && _order != null && !e.offline) return;
      if (_order != null) Toast.error(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    return PurplePage(
      header: _DetailHeader(order: o, code: widget.code),
      body: RefreshIndicator(
        onRefresh: () => _load(silent: false),
        color: context.palette.accent,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(context.sp(16), context.sp(14), context.sp(16), context.bottomInset + context.sp(24)),
          children: <Widget>[
            if (o == null && _loading) const LoadingBlock(),
            if (o == null && !_loading && _error != null)
              EmptyState(
                icon: Icons.cloud_off_rounded,
                text: _error!,
                action: TextButton(onPressed: () => _load(), child: const Text('Try again')),
              ),
            if (o != null) ..._sections(context, o),
          ],
        ),
      ),
      bottom: o != null && o.isActive
          ? Container(
              padding: EdgeInsets.fromLTRB(context.sp(16), context.sp(12), context.sp(16), context.bottomInset + context.sp(12)),
              decoration: BoxDecoration(
                color: context.palette.card,
                boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x141C1726), blurRadius: 18, offset: Offset(0, -6))],
              ),
              child: OrderActionRow(order: o),
            )
          : null,
    );
  }

  List<Widget> _sections(BuildContext context, RiderOrder o) {
    final gap = SizedBox(height: context.sp(16));
    final points = o.isDelivered ? decodePolyline(o.route) : const <LatLngPoint>[];
    var i = 0;
    return <Widget>[
      if (o.isCancelled) ...<Widget>[
        const SectionLabel('Reason'),
        Stagger(index: i++, child: ReasonBox(order: o)),
        gap,
      ],
      const SectionLabel('Customer'),
      Stagger(index: i++, child: _CustomerCard(order: o)),
      gap,
      const SectionLabel('Timeline'),
      Stagger(index: i++, child: _TimelineCard(order: o)),
      if (o.isDelivered && points.length >= 2) ...<Widget>[
        gap,
        const SectionLabel('Route'),
        Stagger(index: i++, child: _RouteCard(order: o, points: points)),
      ],
      gap,
      const SectionLabel('Items'),
      Stagger(index: i++, child: _ItemsCard(order: o)),
    ];
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.order, required this.code});

  final RiderOrder? order;
  final String code;

  @override
  Widget build(BuildContext context) {
    final o = order;
    return HeaderSurface(
      child: Padding(
        padding: EdgeInsets.fromLTRB(context.sp(18), context.topInset + context.sp(14), context.sp(18), context.sp(26)),
        child: Row(
          children: <Widget>[
            const HeaderBackButton(),
            SizedBox(width: context.sp(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    o?.code ?? code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: context.sp(20), fontWeight: FontWeight.w700),
                  ),
                  if (o != null)
                    Text(
                      Fmt.dateTime(o.assignedAt ?? o.createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: const Color(0xCCFFFFFF), fontSize: context.sp(12.5)),
                    ),
                ],
              ),
            ),
            if (o != null) ...<Widget>[
              SizedBox(width: context.sp(8)),
              StatusChip(status: o.status, label: o.statusLabel.isEmpty ? Fmt.titleCase(o.status) : o.statusLabel, onDark: true),
            ],
          ],
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order});

  final RiderOrder order;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = order.customer;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.text, fontSize: context.sp(15.5), fontWeight: FontWeight.w700),
                    ),
                    if (c.phone.isNotEmpty)
                      Text(
                        c.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.muted, fontSize: context.sp(13), letterSpacing: 0.3),
                      ),
                  ],
                ),
              ),
              if (c.phone.isNotEmpty)
                RoundIconButton(
                  icon: Icons.call_outlined,
                  color: AppColors.delivered,
                  background: AppColors.greenSoft,
                  size: context.sp(46),
                  onTap: () => OrderActions.call(c.name, c.phone),
                ),
            ],
          ),
          if (c.address.isNotEmpty) ...<Widget>[
            SizedBox(height: context.sp(10)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: context.sp(1)),
                  child: Icon(Icons.location_on_outlined, size: context.sp(16), color: p.muted),
                ),
                SizedBox(width: context.sp(8)),
                Expanded(
                  child: Text(
                    c.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.text2, fontSize: context.sp(13)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.order});

  final RiderOrder order;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final o = order;
    final steps = <_Step>[
      _Step('Assigned', o.assignedAt, AppColors.assigned),
      if (o.dispatchedAt != null || o.isOut || o.isDelivered) _Step('Out for delivery', o.dispatchedAt, AppColors.ofd),
      if (o.isDelivered) _Step('Delivered', o.deliveredAt, AppColors.delivered),
      if (o.isCancelled) _Step('Cancelled', o.cancelledAt, p.cancel),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (var i = 0; i < steps.length; i++)
            _TimelineRow(step: steps[i], first: i == 0, last: i == steps.length - 1),
          if (o.isDelivered) ...<Widget>[
            SizedBox(height: context.sp(12)),
            Container(
              padding: EdgeInsets.symmetric(vertical: context.sp(12)),
              decoration: BoxDecoration(color: const Color(0xFFF7F4FC), borderRadius: BorderRadius.circular(context.sp(14))),
              child: IntrinsicHeight(
                child: Row(
                  children: <Widget>[
                    Expanded(child: _Metric(value: Fmt.minutes(o.deliveryMin), label: 'Delivery time')),
                    Container(width: 1, color: AppColors.border),
                    Expanded(child: _Metric(value: Fmt.km(o.km), label: 'Distance')),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Step {
  const _Step(this.label, this.time, this.color);

  final String label;
  final DateTime? time;
  final Color color;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.first, required this.last});

  final _Step step;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dot = context.sp(12);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: dot,
            child: Column(
              children: <Widget>[
                Expanded(child: Container(width: 2, color: first ? Colors.transparent : const Color(0xFFE6E0F0))),
                Container(width: dot, height: dot, decoration: BoxDecoration(color: step.color, shape: BoxShape.circle)),
                Expanded(child: Container(width: 2, color: last ? Colors.transparent : const Color(0xFFE6E0F0))),
              ],
            ),
          ),
          SizedBox(width: context.sp(14)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: context.sp(9)),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      step.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.text, fontSize: context.sp(14)),
                    ),
                  ),
                  Text(Fmt.time(step.time), style: TextStyle(color: p.muted, fontSize: context.sp(13))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: TextStyle(color: p.text, fontSize: context.sp(17), fontWeight: FontWeight.w700)),
        ),
        SizedBox(height: context.sp(2)),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: context.sp(11.5))),
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.order, required this.points});

  final RiderOrder order;
  final List<LatLngPoint> points;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(context.sp(18)),
      child: AspectRatio(
        aspectRatio: 16 / 8,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: RouteMap(points: points, lineColor: AppColors.amber, startColor: p.accent, endColor: AppColors.delivered),
            ),
            Positioned(
              left: context.sp(12),
              bottom: context.sp(10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: context.sp(10), vertical: context.sp(4)),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                child: Text(
                  'Your route ${Fmt.km(order.actualKm ?? order.km)}',
                  style: TextStyle(color: const Color(0xFFC2410C), fontSize: context.sp(11), fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});

  final RiderOrder order;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final o = order;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final item in o.items)
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.sp(5)),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.text, fontSize: context.sp(13.5)),
                    ),
                  ),
                  SizedBox(width: context.sp(10)),
                  Text(
                    '${item.qty} × ${Fmt.number(item.price)}',
                    style: TextStyle(color: p.muted, fontSize: context.sp(13)),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.sp(12)),
            child: const Divider(height: 1, thickness: 1, color: AppColors.border),
          ),
          _BillLine(label: 'Subtotal', value: Fmt.money(o.subtotal)),
          if (o.discount > 0) _BillLine(label: 'Discount', value: '– ${Fmt.money(o.discount)}'),
          _BillLine(label: 'Delivery', value: Fmt.money(o.fee)),
          SizedBox(height: context.sp(6)),
          _BillLine(label: 'Total · ${o.paymentShort}', value: Fmt.money(o.total), strong: true),
          if (o.remarks.isNotEmpty) ...<Widget>[
            SizedBox(height: context.sp(10)),
            Text(o.remarks, style: TextStyle(color: AppColors.text2, fontSize: context.sp(12.5))),
          ],
        ],
      ),
    );
  }
}

class _BillLine extends StatelessWidget {
  const _BillLine({required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.sp(4)),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: strong ? p.text : AppColors.text2,
                fontSize: context.sp(strong ? 15.5 : 13.5),
                fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: strong ? p.text : AppColors.text2,
              fontSize: context.sp(strong ? 15.5 : 13.5),
              fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
