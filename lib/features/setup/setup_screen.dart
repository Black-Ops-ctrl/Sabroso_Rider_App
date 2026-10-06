import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/scale.dart';
import '../../widgets/slide_button.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';
import '../shell/app_flow.dart';

class PermissionMeta {
  const PermissionMeta(this.permission, this.icon, this.title, this.subtitle);

  final PhonePermission permission;
  final IconData icon;
  final String title;
  final String subtitle;
}

const List<PermissionMeta> kSetupItems = <PermissionMeta>[
  PermissionMeta(PhonePermission.gps, Icons.gps_fixed_rounded, 'GPS', 'Turn on phone location'),
  PermissionMeta(PhonePermission.location, Icons.location_on_outlined, 'Location access', 'Set to "Allow all the time"'),
  PermissionMeta(PhonePermission.notifications, Icons.notifications_none_rounded, 'Notifications', 'Alerts for new orders'),
  PermissionMeta(PhonePermission.battery, Icons.battery_full_rounded, 'Battery', 'Set to "No restrictions"'),
];

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with WidgetsBindingObserver {
  PermissionState _state = const PermissionState();
  PhonePermission? _pending;
  bool _loaded = false;

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
    final pending = _pending;
    setState(() {
      _state = s;
      _loaded = true;
    });
    if (pending != null) {
      _pending = null;
      Toast.result(s.of(pending), s.of(pending) ? PermissionService.allowedMessage(pending) : PermissionService.failedMessage(pending));
    }
  }

  Future<void> _allow(PhonePermission p) async {
    _pending = p;
    await PermissionService.request(p);
    if (p != PhonePermission.gps) await _check();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final step = _state.granted >= 4 ? 4 : _state.granted + 1;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: kLightBar,
      child: Scaffold(
        backgroundColor: p.background,
        body: Column(
          children: <Widget>[
            HeaderSurface(
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.sp(24), context.topInset + context.sp(12), context.sp(20), context.sp(30)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        color: const Color(0x2EFFFFFF),
                        shape: const StadiumBorder(side: BorderSide(color: Color(0x4DFFFFFF))),
                        child: InkWell(
                          customBorder: const StadiumBorder(),
                          onTap: AppFlow.openShell,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: context.sp(16), vertical: context.sp(7)),
                            child: Text(
                              'Skip',
                              style: TextStyle(color: Colors.white, fontSize: context.sp(13), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: context.sp(4)),
                    Text(
                      'STEP $step OF 4',
                      style: TextStyle(color: const Color(0xCCFFFFFF), fontSize: context.sp(11), letterSpacing: 3),
                    ),
                    SizedBox(height: context.sp(6)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          children: const <InlineSpan>[
                            TextSpan(text: 'Before you ', style: TextStyle(fontWeight: FontWeight.w300)),
                            TextSpan(text: 'start', style: TextStyle(fontWeight: FontWeight.w700)),
                          ],
                          style: TextStyle(color: Colors.white, fontSize: context.sp(27)),
                        ),
                      ),
                    ),
                    SizedBox(height: context.sp(18)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: SizedBox(
                        height: context.sp(5),
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            const ColoredBox(color: Color(0x33FFFFFF)),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: _state.granted / 4),
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, _) => FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: v.clamp(0.0, 1.0),
                                child: const ColoredBox(color: Color(0xFFFBBF24)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: !_loaded
                  ? const LoadingBlock()
                  : ListView(
                      padding: EdgeInsets.fromLTRB(context.sp(18), context.sp(16), context.sp(18), context.sp(16)),
                      children: <Widget>[
                        for (var i = 0; i < kSetupItems.length; i++)
                          Stagger(
                            index: i,
                            child: Padding(
                              padding: EdgeInsets.only(bottom: context.sp(12)),
                              child: _SetupCard(
                                meta: kSetupItems[i],
                                done: _state.of(kSetupItems[i].permission),
                                onAllow: () => _allow(kSetupItems[i].permission),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(context.sp(22), context.sp(8), context.sp(22), context.bottomInset + context.sp(18)),
              child: SlideButton(
                label: 'Slide to continue',
                busyLabel: 'Opening…',
                enabled: _state.all,
                onSubmit: () async {
                  final s = await PermissionService.check();
                  if (!s.all) {
                    if (mounted) setState(() => _state = s);
                    Toast.error('Allow all four to continue');
                    return false;
                  }
                  Toast.success('All set');
                  AppFlow.openShell();
                  return true;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.meta, required this.done, required this.onAllow});

  final PermissionMeta meta;
  final bool done;
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: context.sp(14), vertical: context.sp(14)),
      child: Row(
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: context.sp(46),
            height: context.sp(46),
            decoration: BoxDecoration(
              color: done ? AppColors.greenSoft : AppColors.lavender,
              borderRadius: BorderRadius.circular(context.sp(14)),
            ),
            child: Icon(meta.icon, color: done ? AppColors.delivered : p.accent, size: context.sp(22)),
          ),
          SizedBox(width: context.sp(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  meta.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.text, fontSize: context.sp(15), fontWeight: FontWeight.w600),
                ),
                SizedBox(height: context.sp(2)),
                Text(
                  meta.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.muted, fontSize: context.sp(12)),
                ),
              ],
            ),
          ),
          SizedBox(width: context.sp(8)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
            child: done
                ? Container(
                    key: const ValueKey<String>('done'),
                    width: context.sp(40),
                    height: context.sp(40),
                    decoration: const BoxDecoration(color: AppColors.delivered, shape: BoxShape.circle),
                    child: Icon(Icons.check_rounded, color: Colors.white, size: context.sp(22)),
                  )
                : Material(
                    key: const ValueKey<String>('allow'),
                    color: p.text,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: onAllow,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.sp(18), vertical: context.sp(10)),
                        child: Text(
                          'Allow',
                          style: TextStyle(color: Colors.white, fontSize: context.sp(13), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
