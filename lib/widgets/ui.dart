import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/brand_provider.dart';
import '../theme/scale.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.margin, this.color, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(context.sp(18));
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? p.card,
        borderRadius: radius,
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x0F1C1726), blurRadius: 22, offset: Offset(0, 8))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding ?? EdgeInsets.all(context.sp(16)), child: child),
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = TextStyle(color: p.muted, fontSize: context.sp(11), letterSpacing: 2, fontWeight: FontWeight.w500);
    return Padding(
      padding: EdgeInsets.fromLTRB(context.sp(4), context.sp(6), context.sp(4), context.sp(8)),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(text.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: style)),
          if (trailing != null) Text(trailing!, maxLines: 1, style: style),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, required this.label, this.onDark = false});

  final String status;
  final String label;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = p.statusColor(status);
    final bg = p.statusSoft(status);
    return Container(
      constraints: BoxConstraints(maxWidth: context.sp(120)),
      padding: EdgeInsets.symmetric(horizontal: context.sp(9), vertical: context.sp(3)),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: fg, fontSize: context.sp(onDark ? 12.0 : 10.5), fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.color, required this.background, this.onTap, this.size});

  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback? onTap;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final s = size ?? context.sp(42);
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: s, height: s, child: Icon(icon, color: color, size: s * 0.46)),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.gradient,
    this.onTap,
    this.busy = false,
    this.icon,
    this.height,
    this.textColor = Colors.white,
    this.shadowColor,
  });

  final String label;
  final Gradient gradient;
  final VoidCallback? onTap;
  final bool busy;
  final IconData? icon;
  final double? height;
  final Color textColor;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final h = height ?? context.sp(46);
    final enabled = onTap != null && !busy;
    final radius = BorderRadius.circular(999);
    return Opacity(
      opacity: onTap == null && !busy ? 0.55 : 1.0,
      child: Container(
        constraints: BoxConstraints(minHeight: h),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: radius,
          boxShadow: shadowColor == null
              ? null
              : <BoxShadow>[BoxShadow(color: shadowColor!, blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.sp(14), vertical: context.sp(10)),
              child: Center(
                child: busy
                    ? SizedBox(
                        width: context.sp(20),
                        height: context.sp(20),
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: textColor),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (icon != null) ...<Widget>[
                            Icon(icon, color: textColor, size: context.sp(18)),
                            SizedBox(width: context.sp(8)),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontSize: context.sp(14.5),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppToggle extends StatelessWidget {
  const AppToggle({super.key, required this.value, required this.onChanged, this.activeColor, this.busy = false});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final w = context.sp(52);
    final h = context.sp(30);
    final knob = h - context.sp(6);
    final on = activeColor ?? p.accent;
    return Semantics(
      toggled: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null || busy ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: w,
          height: h,
          padding: EdgeInsets.all(context.sp(3)),
          decoration: BoxDecoration(
            color: value ? on : const Color(0xFFE7E3EE),
            borderRadius: BorderRadius.circular(999),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: knob,
              height: knob,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: busy
                  ? SizedBox(
                      width: knob * 0.55,
                      height: knob * 0.55,
                      child: CircularProgressIndicator(strokeWidth: 2, color: on),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class Stagger extends StatefulWidget {
  const Stagger({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<Stagger> createState() => _StaggerState();
}

class _StaggerState extends State<Stagger> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final CurvedAnimation _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    final delay = 60 * (widget.index > 8 ? 8 : widget.index);
    Future<void>.delayed(Duration(milliseconds: delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _a.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(_a),
        child: widget.child,
      ),
    );
  }
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, required this.height, this.onDark = true, this.maxWidth});

  final double height;
  final bool onDark;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final brand = context.watch<BrandProvider>().brand;
    final logo = brand.logo;
    final width = maxWidth ?? height * 4;
    if (logo != null) {
      final Widget img = brand.svg
          ? SvgPicture.memory(logo, height: height, fit: BoxFit.contain)
          : Image.memory(logo, height: height, fit: BoxFit.contain, gaplessPlayback: true);
      return ConstrainedBox(constraints: BoxConstraints(maxWidth: width, maxHeight: height), child: img);
    }
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: Text(
        brand.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: onDark ? Colors.white : context.palette.text,
          fontSize: height * 0.55,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.sp(40), horizontal: context.sp(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: context.sp(84),
            height: context.sp(84),
            decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
            child: Icon(icon, color: p.accent, size: context.sp(36)),
          ),
          SizedBox(height: context.sp(16)),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.text, fontSize: context.sp(14.5), fontWeight: FontWeight.w600),
          ),
          if (action != null) ...<Widget>[SizedBox(height: context.sp(14)), action!],
        ],
      ),
    );
  }
}

class LoadingBlock extends StatelessWidget {
  const LoadingBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.sp(40)),
      child: Center(
        child: SizedBox(
          width: context.sp(28),
          height: context.sp(28),
          child: CircularProgressIndicator(strokeWidth: 2.6, color: context.palette.accent),
        ),
      ),
    );
  }
}

class HeaderSurface extends StatelessWidget {
  const HeaderSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: p.header,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(context.sp(28))),
      ),
      child: child,
    );
  }
}

class HeaderBackButton extends StatelessWidget {
  const HeaderBackButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return HeaderIconButton(
      icon: Icons.chevron_left_rounded,
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
    );
  }
}

class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({super.key, required this.icon, required this.onTap, this.active = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final s = context.sp(40);
    return Material(
      color: active ? Colors.white : const Color(0x26FFFFFF),
      shape: const CircleBorder(side: BorderSide(color: Color(0x40FFFFFF))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: s,
          height: s,
          child: Icon(icon, color: active ? context.palette.accent : Colors.white, size: s * 0.58),
        ),
      ),
    );
  }
}

class SubPageHeader extends StatelessWidget {
  const SubPageHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return HeaderSurface(
      child: Padding(
        padding: EdgeInsets.fromLTRB(context.sp(18), context.topInset + context.sp(14), context.sp(18), context.sp(26)),
        child: Row(
          children: <Widget>[
            const HeaderBackButton(),
            SizedBox(width: context.sp(12)),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: context.sp(20), fontWeight: FontWeight.w500),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class PurplePage extends StatelessWidget {
  const PurplePage({super.key, required this.header, required this.body, this.bottom});

  final Widget header;
  final Widget body;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: kLightBar,
      child: Scaffold(
        backgroundColor: context.palette.background,
        body: Column(
          children: <Widget>[
            header,
            Expanded(child: body),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}

class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, required this.color, required this.background, this.size});

  final IconData icon;
  final Color color;
  final Color background;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final s = size ?? context.sp(44);
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(s * 0.3)),
      child: Icon(icon, color: color, size: s * 0.5),
    );
  }
}
