import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../theme/app_colors.dart';
import '../../theme/scale.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';
import '../auth/session_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SessionProvider>().refreshMe();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.watch<SessionProvider>().rider;
    String v(String s) => s.isEmpty ? '—' : s;
    final rows = <List<String>>[
      <String>['Rider ID', v(r?.code ?? '')],
      <String>['Employee ID', v(r?.empId ?? '')],
      <String>['Name', v(r?.name ?? '')],
      <String>['Mobile', v(r?.phone ?? '')],
      <String>['Shop', v(r?.shop?.name ?? '')],
      <String>['Username', v(r?.username ?? '')],
      <String>['Password', v(r?.password ?? '')],
      <String>['Joined', r?.joined == null ? '—' : Fmt.date(r!.joined)],
      <String>['Status', v(Fmt.titleCase(r?.status ?? ''))],
    ];
    return PurplePage(
      header: SubPageHeader(
        title: 'Profile',
        trailing: HeaderIconButton(
          icon: _show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          active: _show,
          onTap: () {
            setState(() => _show = !_show);
            Toast.info(_show ? 'Details shown' : 'Details hidden');
          },
        ),
      ),
      body: RefreshIndicator(
        color: p.accent,
        onRefresh: () => context.read<SessionProvider>().refreshMe(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(context.sp(16), context.sp(16), context.sp(16), context.bottomInset + context.sp(24)),
          children: <Widget>[
            Stagger(
              index: 0,
              child: AppCard(
                padding: EdgeInsets.symmetric(horizontal: context.sp(16), vertical: context.sp(4)),
                child: Column(
                  children: <Widget>[
                    for (var i = 0; i < rows.length; i++) ...<Widget>[
                      if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.border),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: context.sp(13)),
                        child: Row(
                          children: <Widget>[
                            Text(rows[i][0], style: TextStyle(color: p.muted, fontSize: context.sp(13))),
                            SizedBox(width: context.sp(16)),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (child, a) => FadeTransition(opacity: a, child: child),
                                layoutBuilder: (current, previous) => Stack(
                                  alignment: Alignment.centerRight,
                                  children: <Widget>[...previous, if (current != null) current],
                                ),
                                child: Text(
                                  _show ? rows[i][1] : '••••••',
                                  key: ValueKey<bool>(_show),
                                  textAlign: TextAlign.right,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _show ? p.text : p.muted,
                                    fontSize: context.sp(13.5),
                                    fontWeight: _show ? FontWeight.w600 : FontWeight.w400,
                                    letterSpacing: _show ? 0.2 : 2.0,
                                  ),
                                ),
                              ),
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
      ),
    );
  }
}
