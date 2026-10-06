import 'package:flutter/material.dart';

import '../../services/permission_service.dart';
import '../../theme/scale.dart';
import '../../theme/app_colors.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';

class _Item {
  const _Item(this.permission, this.icon, this.subtitle);

  final PhonePermission permission;
  final IconData icon;
  final String subtitle;
}

const List<_Item> _items = <_Item>[
  _Item(PhonePermission.gps, Icons.gps_fixed_rounded, 'Phone location'),
  _Item(PhonePermission.location, Icons.location_on_outlined, 'Allow all the time'),
  _Item(PhonePermission.notifications, Icons.notifications_none_rounded, 'New order alerts'),
  _Item(PhonePermission.battery, Icons.battery_full_rounded, 'No restrictions'),
];

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> with WidgetsBindingObserver {
  PermissionState? _state;
  PhonePermission? _pending;
  bool? _pendingTarget;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final s = await PermissionService.check();
    if (!mounted) return;
    setState(() => _state = s);
    final p = _pending;
    final target = _pendingTarget;
    if (p != null && target != null) {
      _pending = null;
      _pendingTarget = null;
      final now = s.of(p);
      if (target) {
        Toast.result(now, now ? PermissionService.allowedMessage(p) : PermissionService.failedMessage(p));
      } else {
        Toast.result(!now, now ? '${PermissionService.label(p)} is still on' : '${PermissionService.label(p)} turned off');
      }
    }
  }

  Future<void> _toggle(PhonePermission p, bool on) async {
    _pending = p;
    _pendingTarget = on;
    if (on) {
      await PermissionService.request(p);
      if (p != PhonePermission.gps) await _check();
    } else {
      await PermissionService.openSettingsFor(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = _state;
    return PurplePage(
      header: const SubPageHeader(title: 'App settings'),
      body: s == null
          ? const LoadingBlock()
          : ListView(
              padding: EdgeInsets.fromLTRB(context.sp(16), context.sp(16), context.sp(16), context.bottomInset + context.sp(24)),
              children: <Widget>[
                Stagger(
                  index: 0,
                  child: AppCard(
                    padding: EdgeInsets.symmetric(horizontal: context.sp(14), vertical: context.sp(6)),
                    child: Column(
                      children: <Widget>[
                        for (var i = 0; i < _items.length; i++) ...<Widget>[
                          if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.border),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: context.sp(12)),
                            child: Row(
                              children: <Widget>[
                                IconTile(icon: _items[i].icon, color: p.accent, background: AppColors.lavender, size: context.sp(42)),
                                SizedBox(width: context.sp(14)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        PermissionService.label(_items[i].permission),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: p.text, fontSize: context.sp(14.5), fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        _items[i].subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: p.muted, fontSize: context.sp(12)),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: context.sp(8)),
                                AppToggle(
                                  value: s.of(_items[i].permission),
                                  onChanged: (v) => _toggle(_items[i].permission, v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
