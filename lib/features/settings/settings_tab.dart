import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../theme/app_colors.dart';
import '../../theme/scale.dart';
import '../../widgets/routes.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';
import '../auth/login_screen.dart';
import '../auth/session_provider.dart';
import '../orders/orders_provider.dart';
import '../shell/floating_nav.dart';
import '../shell/shell_screen.dart';
import 'app_settings_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _busy = false;

  Future<void> _logout() async {
    if (_busy) return;
    final session = context.read<SessionProvider>();
    final orders = context.read<OrdersProvider>();
    final pending = orders.loaded ? orders.activeCount : (session.rider?.openOrders ?? 0);
    if (pending > 0) {
      Toast.error('Deliver all orders to log out');
      return;
    }
    final yes = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x661C1726),
      builder: (_) => const _ConfirmDialog(),
    );
    if (yes != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await session.logout();
      Toast.success('Logged out');
      Nav.replaceAll(const LoginScreen());
    } on ApiException catch (e) {
      Toast.error(e.or("Couldn't log out. Try again"));
    } catch (_) {
      Toast.error("Couldn't log out. Try again");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rider = context.watch<SessionProvider>().rider;
    final unread = rider?.unread ?? 0;
    return Column(
      children: <Widget>[
        TabHeader(
          tab: 3,
          child: Text(
            'Settings',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontSize: context.sp(24), fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: p.accent,
            onRefresh: () => context.read<SessionProvider>().refreshMe(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(context.sp(16), context.sp(16), context.sp(16), navReserve(context)),
              children: <Widget>[
                Stagger(
                  index: 0,
                  child: AppCard(
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: context.sp(50),
                          height: context.sp(50),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: p.accentButton),
                          child: Text(
                            Fmt.initials(rider?.name ?? ''),
                            style: TextStyle(color: Colors.white, fontSize: context.sp(16), fontWeight: FontWeight.w700),
                          ),
                        ),
                        SizedBox(width: context.sp(14)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                rider?.name ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: p.text, fontSize: context.sp(15.5), fontWeight: FontWeight.w700),
                              ),
                              if ((rider?.shop?.name ?? '').isNotEmpty)
                                Text(
                                  rider!.shop!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: p.muted, fontSize: context.sp(12.5)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: context.sp(14)),
                Stagger(
                  index: 1,
                  child: AppCard(
                    padding: EdgeInsets.symmetric(horizontal: context.sp(6), vertical: context.sp(6)),
                    child: Column(
                      children: <Widget>[
                        _MenuRow(
                          icon: Icons.tune_rounded,
                          iconColor: p.accent,
                          iconBg: AppColors.lavender,
                          title: 'App settings',
                          subtitle: 'Permissions',
                          onTap: () => Nav.push<void>(const AppSettingsScreen()),
                        ),
                        const Divider(height: 1, thickness: 1, color: AppColors.border, indent: 12, endIndent: 12),
                        _MenuRow(
                          icon: Icons.person_outline_rounded,
                          iconColor: AppColors.ofd,
                          iconBg: AppColors.ofdSoft,
                          title: 'Profile',
                          subtitle: 'Your details',
                          onTap: () => Nav.push<void>(const ProfileScreen()),
                        ),
                        const Divider(height: 1, thickness: 1, color: AppColors.border, indent: 12, endIndent: 12),
                        _MenuRow(
                          icon: Icons.notifications_none_rounded,
                          iconColor: const Color(0xFFD97706),
                          iconBg: const Color(0xFFFEF3C7),
                          title: 'Notifications',
                          subtitle: 'Order alerts',
                          badge: unread,
                          onTap: () => Nav.push<void>(const NotificationsScreen()),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: context.sp(24)),
                Stagger(
                  index: 2,
                  child: Material(
                    color: p.card,
                    shape: StadiumBorder(side: BorderSide(color: fade(p.cancel, 0.35))),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: _busy ? null : _logout,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: context.sp(14)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            _busy
                                ? SizedBox(
                                    width: context.sp(18),
                                    height: context.sp(18),
                                    child: CircularProgressIndicator(strokeWidth: 2, color: p.cancel),
                                  )
                                : Icon(Icons.logout_rounded, color: p.cancel, size: context.sp(18)),
                            SizedBox(width: context.sp(8)),
                            Text(
                              'Log out',
                              style: TextStyle(color: p.cancel, fontSize: context.sp(14.5), fontWeight: FontWeight.w600),
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
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(context.sp(14)),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.sp(10), vertical: context.sp(12)),
        child: Row(
          children: <Widget>[
            IconTile(icon: icon, color: iconColor, background: iconBg, size: context.sp(42)),
            SizedBox(width: context.sp(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.text, fontSize: context.sp(14.5), fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.muted, fontSize: context.sp(12)),
                  ),
                ],
              ),
            ),
            if (badge > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.sp(8), vertical: context.sp(2)),
                decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(99)),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: TextStyle(color: Colors.white, fontSize: context.sp(11), fontWeight: FontWeight.w700),
                ),
              ),
            SizedBox(width: context.sp(6)),
            Icon(Icons.chevron_right_rounded, color: p.muted, size: context.sp(20)),
          ],
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Dialog(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: context.sp(32)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.sp(22))),
      child: Padding(
        padding: EdgeInsets.fromLTRB(context.sp(22), context.sp(24), context.sp(22), context.sp(18)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(child: IconTile(icon: Icons.logout_rounded, color: p.cancel, background: AppColors.cancelledSoft, size: context.sp(52))),
            SizedBox(height: context.sp(14)),
            Text(
              'Are you sure?',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.text, fontSize: context.sp(17), fontWeight: FontWeight.w700),
            ),
            SizedBox(height: context.sp(20)),
            Row(
              children: <Widget>[
                Expanded(
                  child: GradientButton(
                    label: 'Cancel',
                    gradient: const LinearGradient(colors: <Color>[Color(0xFFF1EEF6), Color(0xFFF1EEF6)]),
                    textColor: p.text,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                SizedBox(width: context.sp(12)),
                Expanded(
                  child: GradientButton(
                    label: 'Log out',
                    gradient: p.cancelButton,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
