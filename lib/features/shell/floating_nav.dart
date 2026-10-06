import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/scale.dart';

class NavItem {
  const NavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

const List<NavItem> kNavItems = <NavItem>[
  NavItem(Icons.home_outlined, 'Home'),
  NavItem(Icons.receipt_long_outlined, 'Orders'),
  NavItem(Icons.history_rounded, 'History'),
  NavItem(Icons.settings_outlined, 'Settings'),
];

double navReserve(BuildContext context) => context.sp(64) + context.bottomInset + context.sp(30);

class FloatingNav extends StatefulWidget {
  const FloatingNav({super.key, required this.index, required this.onTap, this.badge = 0});

  final int index;
  final ValueChanged<int> onTap;
  final int badge;

  @override
  State<FloatingNav> createState() => _FloatingNavState();
}

class _FloatingNavState extends State<FloatingNav> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520), value: 1);
  late int _from = widget.index;
  late int _to = widget.index;

  @override
  void didUpdateWidget(covariant FloatingNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _to) {
      _from = _c.value > 0.5 ? _to : _from;
      _to = widget.index;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _eo(double x) {
    final v = x.clamp(0.0, 1.0);
    return 1 - math.pow(1 - v, 3).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final height = context.sp(64);
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: <Color>[p.navTop, p.navBottom]),
        borderRadius: BorderRadius.circular(999),
        boxShadow: <BoxShadow>[BoxShadow(color: fade(p.navBottom, 0.38), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final slot = box.maxWidth / kNavItems.length;
          final inset = context.sp(8);
          final half = slot / 2 - inset * 0.5;
          double cx(int i) => slot * i + slot / 2;
          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value;
              final head = cx(_from) + (cx(_to) - cx(_from)) * _eo(t * 1.6);
              final tail = cx(_from) + (cx(_to) - cx(_from)) * _eo(t * 0.9);
              final left = math.min(head, tail) - half;
              final right = math.max(head, tail) + half;
              final activeIndex = t > 0.5 ? _to : _from;
              return Stack(
                children: <Widget>[
                  Positioned(
                    left: left.clamp(inset * 0.5, math.max(inset * 0.5, box.maxWidth)).toDouble(),
                    width: (right - left).clamp(0.0, math.max(0.0, box.maxWidth - inset)).toDouble(),
                    top: inset,
                    bottom: inset,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: p.navPill,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
                      ),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      for (var i = 0; i < kNavItems.length; i++)
                        Expanded(
                          child: _NavButton(
                            item: kNavItems[i],
                            active: i == activeIndex,
                            badge: i == 1 ? widget.badge : 0,
                            onTap: () => widget.onTap(i),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.active, required this.badge, required this.onTap});

  final NavItem item;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = active ? p.navActive : const Color(0xC8FFFFFF);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        customBorder: const StadiumBorder(),
        splashColor: const Color(0x33FFFFFF),
        highlightColor: const Color(0x14FFFFFF),
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Icon(item.icon, color: color, size: context.sp(21)),
                  if (badge > 0)
                    Positioned(
                      right: -context.sp(10),
                      top: -context.sp(7),
                      child: Container(
                        constraints: BoxConstraints(minWidth: context.sp(17), minHeight: context.sp(17)),
                        padding: EdgeInsets.symmetric(horizontal: context.sp(4)),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          badge > 99 ? '99+' : '$badge',
                          style: TextStyle(color: Colors.white, fontSize: context.sp(9.5), fontWeight: FontWeight.w700, height: 1.1),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: context.sp(2)),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  color: color,
                  fontSize: context.sp(10.5),
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
