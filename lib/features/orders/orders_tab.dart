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
import '../settings/app_settings_screen.dart';
import '../shell/floating_nav.dart';
import '../shell/shell_screen.dart';
import 'duty_provider.dart';
import 'order_actions.dart';
import 'orders_provider.dart';
import 'widgets/order_card.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  bool _shopBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final orders = context.read<OrdersProvider>();
      orders.load(silent: orders.loaded);
    });
  }

  Future<void> _refresh() async {
    final orders = context.read<OrdersProvider>();
    await orders.load(silent: true);
    final err = orders.error;
    if (err != null) Toast.error(err);
  }

  Future<void> _goShop() async {
    if (_shopBusy) return;
    setState(() => _shopBusy = true);
    await OrderActions.goToShop(context);
    if (mounted) setState(() => _shopBusy = false);
  }

  Future<void> _toggleDuty(bool on) async {
    final duty = context.read<DutyProvider>();
    final orders = context.read<OrdersProvider>();
    final r = await duty.setDuty(on, activeOrders: orders.activeCount);
    if (r.message.isEmpty) return;
    Toast.result(r.ok, r.message);
    if (!r.ok && on && r.message.startsWith('Allow location')) {
      Nav.push<void>(const AppSettingsScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final orders = context.watch<OrdersProvider>();
    final list = orders.visible;
    return Column(
      children: <Widget>[
        TabHeader(
          tab: 1,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Orders',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: context.sp(24), fontWeight: FontWeight.w500),
                ),
              ),
              _GoShopButton(busy: _shopBusy, onTap: _goShop),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: p.accent,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(context.sp(16), context.sp(16), context.sp(16), navReserve(context)),
              children: <Widget>[
                Stagger(index: 0, child: _DutyCard(onChanged: _toggleDuty)),
                SizedBox(height: context.sp(14)),
                _FilterChips(
                  counts: orders.counts,
                  selected: orders.filter,
                  onSelect: orders.setFilter,
                ),
                SizedBox(height: context.sp(14)),
                if (!orders.loaded && orders.loading) const LoadingBlock(),
                if (!orders.loaded && !orders.loading && orders.error != null)
                  EmptyState(
                    icon: Icons.cloud_off_rounded,
                    text: orders.error!,
                    action: TextButton(onPressed: () => orders.load(), child: const Text('Try again')),
                  ),
                if (orders.loaded && list.isEmpty)
                  const EmptyState(icon: Icons.receipt_long_outlined, text: 'No orders'),
                for (var i = 0; i < list.length; i++)
                  Padding(
                    key: ValueKey<int>(list[i].id),
                    padding: EdgeInsets.only(bottom: context.sp(14)),
                    child: Stagger(
                      index: i + 1,
                      child: OrderCard(
                        order: list[i],
                        onOpen: () => Nav.push<void>(OrderDetailScreen(orderId: list[i].id, code: list[i].code)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GoShopButton extends StatelessWidget {
  const _GoShopButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(999);
    return Container(
      decoration: BoxDecoration(
        gradient: p.goShop,
        borderRadius: radius,
        boxShadow: <BoxShadow>[BoxShadow(color: fade(p.goShopBottom, 0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: busy ? null : onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.sp(14), vertical: context.sp(9)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                busy
                    ? SizedBox(
                        width: context.sp(15),
                        height: context.sp(15),
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(Icons.navigation_outlined, color: Colors.white, size: context.sp(16)),
                SizedBox(width: context.sp(6)),
                Text(
                  'Go to shop',
                  style: TextStyle(color: Colors.white, fontSize: context.sp(13), fontWeight: FontWeight.w600, letterSpacing: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DutyCard extends StatelessWidget {
  const _DutyCard({required this.onChanged});

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final duty = context.watch<DutyProvider>();
    final on = duty.onDuty;
    final since = duty.since;
    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: context.sp(16), vertical: context.sp(14)),
      child: Row(
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: context.sp(46),
            height: context.sp(46),
            decoration: BoxDecoration(
              color: on ? AppColors.greenSoft : const Color(0xFFF1EEF6),
              borderRadius: BorderRadius.circular(context.sp(14)),
            ),
            child: Icon(Icons.pedal_bike_rounded, color: on ? AppColors.delivered : p.muted, size: context.sp(22)),
          ),
          SizedBox(width: context.sp(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  on ? 'On duty' : 'Off duty',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.text, fontSize: context.sp(15.5), fontWeight: FontWeight.w600),
                ),
                if (on && since != null)
                  Text(
                    'Since ${Fmt.time(since)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.muted, fontSize: context.sp(12)),
                  ),
              ],
            ),
          ),
          AppToggle(value: on, busy: duty.busy, activeColor: AppColors.delivered, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.counts, required this.selected, required this.onSelect});

  final StatusCounts counts;
  final String selected;
  final ValueChanged<String> onSelect;

  static const List<List<String>> _items = <List<String>>[
    <String>['ALL', 'All'],
    <String>[OrderStatus.assigned, 'Assigned'],
    <String>[OrderStatus.outForDelivery, 'Out for delivery'],
    <String>[OrderStatus.delivered, 'Delivered'],
    <String>[OrderStatus.cancelled, 'Cancelled'],
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: <Widget>[
          for (final item in _items)
            Padding(
              padding: EdgeInsets.only(right: context.sp(8)),
              child: _Chip(
                label: '${item[1]} ${counts.of(item[0])}',
                active: selected == item[0],
                color: p.accent,
                onTap: () => onSelect(item[0]),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.color, required this.onTap});

  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(999);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: active ? color : p.card,
        borderRadius: radius,
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x0D1C1726), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.sp(15), vertical: context.sp(9)),
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: active ? Colors.white : AppColors.text2,
                fontSize: context.sp(13),
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
