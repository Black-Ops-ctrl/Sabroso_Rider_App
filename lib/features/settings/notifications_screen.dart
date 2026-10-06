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
import 'notifications_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final n = context.read<NotificationsProvider>();
      n.load(silent: n.loaded);
    });
  }

  Future<void> _markAll() async {
    final n = context.read<NotificationsProvider>();
    if (n.rows.every((x) => !x.unread) && n.unread == 0) {
      Toast.info('No unread notifications');
      return;
    }
    final r = await n.markAllRead();
    if (r.message.isNotEmpty) Toast.result(r.ok, r.message);
  }

  Future<void> _refresh() async {
    final n = context.read<NotificationsProvider>();
    await n.load(silent: true);
    final err = n.error;
    if (err != null) Toast.error(err);
  }

  bool _onScroll(ScrollNotification s) {
    if (s.metrics.pixels >= s.metrics.maxScrollExtent - 200) {
      context.read<NotificationsProvider>().loadMore();
    }
    return false;
  }

  void _open(RiderNotification item) {
    final n = context.read<NotificationsProvider>();
    n.markRead(item);
    final id = item.orderId;
    if (id != null) Nav.push<void>(OrderDetailScreen(orderId: id));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = context.watch<NotificationsProvider>();
    return PurplePage(
      header: SubPageHeader(
        title: 'Notifications',
        trailing: TextButton(
          onPressed: n.marking ? null : _markAll,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: context.sp(8)),
            minimumSize: Size(context.sp(40), context.sp(36)),
          ),
          child: Text('Mark all read', style: TextStyle(color: Colors.white, fontSize: context.sp(12), fontWeight: FontWeight.w500)),
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: RefreshIndicator(
          color: p.accent,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(context.sp(16), context.sp(16), context.sp(16), context.bottomInset + context.sp(24)),
            children: <Widget>[
              if (!n.loaded && n.loading) const LoadingBlock(),
              if (!n.loaded && !n.loading && n.error != null)
                EmptyState(
                  icon: Icons.cloud_off_rounded,
                  text: n.error!,
                  action: TextButton(onPressed: () => n.load(), child: const Text('Try again')),
                ),
              if (n.loaded && n.rows.isEmpty) const EmptyState(icon: Icons.notifications_none_rounded, text: 'No notifications'),
              for (var i = 0; i < n.rows.length; i++)
                Padding(
                  key: ValueKey<int>(n.rows[i].id),
                  padding: EdgeInsets.only(bottom: context.sp(10)),
                  child: Stagger(index: i, child: _NotificationTile(item: n.rows[i], onTap: () => _open(n.rows[i]))),
                ),
              if (n.loadingMore) const LoadingBlock(),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final RiderNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final IconData icon;
    final Color color;
    final Color bg;
    switch (item.kind) {
      case 'CANCELLED':
        icon = Icons.close_rounded;
        color = p.cancel;
        bg = AppColors.cancelledSoft;
        break;
      case 'REASSIGNED':
        icon = Icons.pedal_bike_rounded;
        color = const Color(0xFFD97706);
        bg = const Color(0xFFFEF3C7);
        break;
      case 'REMOVED':
        icon = Icons.remove_circle_outline_rounded;
        color = p.muted;
        bg = const Color(0xFFF1EEF6);
        break;
      default:
        icon = Icons.receipt_long_outlined;
        color = p.accent;
        bg = AppColors.lavender;
    }
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.fromLTRB(context.sp(14), context.sp(13), context.sp(14), context.sp(13)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IconTile(icon: icon, color: color, background: bg, size: context.sp(42)),
          SizedBox(width: context.sp(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.text,
                          fontSize: context.sp(13.5),
                          fontWeight: item.unread ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: context.sp(8)),
                    Text(Fmt.ago(item.createdAt), style: TextStyle(color: p.muted, fontSize: context.sp(11))),
                    if (item.unread) ...<Widget>[
                      SizedBox(width: context.sp(8)),
                      Container(
                        width: context.sp(8),
                        height: context.sp(8),
                        decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle),
                      ),
                    ],
                  ],
                ),
                if (item.body.isNotEmpty) ...<Widget>[
                  SizedBox(height: context.sp(3)),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.text2, fontSize: context.sp(12)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
