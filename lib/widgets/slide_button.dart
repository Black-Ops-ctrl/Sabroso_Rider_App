import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/scale.dart';

class SlideButton extends StatefulWidget {
  const SlideButton({
    super.key,
    required this.label,
    required this.busyLabel,
    required this.onSubmit,
    this.enabled = true,
  });

  final String label;
  final String busyLabel;
  final Future<bool> Function() onSubmit;
  final bool enabled;

  @override
  State<SlideButton> createState() => _SlideButtonState();
}

class _SlideButtonState extends State<SlideButton> with TickerProviderStateMixin {
  late final AnimationController _pos = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  late final AnimationController _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  bool _dragging = false;
  bool _busy = false;
  double _travel = 1;

  @override
  void dispose() {
    _pos.dispose();
    _shimmer.dispose();
    _spin.dispose();
    super.dispose();
  }

  void _onDrag(DragUpdateDetails d) {
    if (!widget.enabled || _busy) return;
    _dragging = true;
    _pos.value = (_pos.value + d.delta.dx / _travel).clamp(0.0, 1.0);
  }

  Future<void> _onEnd(DragEndDetails d) async {
    if (!widget.enabled || _busy) return;
    _dragging = false;
    final fast = d.velocity.pixelsPerSecond.dx > 900;
    if (_pos.value > 0.82 || (fast && _pos.value > 0.4)) {
      await _pos.animateTo(1, curve: Curves.easeOutCubic);
      await _submit();
    } else {
      await _pos.animateTo(0, curve: Curves.easeOutBack);
    }
  }

  Future<void> _submit() async {
    if (!mounted) return;
    setState(() => _busy = true);
    _spin.repeat();
    bool ok = false;
    try {
      ok = await widget.onSubmit();
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (!ok) {
      _spin.stop();
      setState(() => _busy = false);
      await _pos.animateTo(0, duration: const Duration(milliseconds: 520), curve: Curves.easeOutBack);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final h = context.sp(58);
    final pad = context.sp(5);
    final knob = h - pad * 2;
    final enabled = widget.enabled;
    final Gradient track = enabled
        ? p.slide
        : const LinearGradient(colors: <Color>[Color(0xFFEDE7F8), Color(0xFFE6DFF4)]);
    final fill = LinearGradient(
      colors: <Color>[Color.lerp(p.slideBottom, Colors.white, 0.08)!, Color.lerp(p.slideBottom, Colors.white, 0.3)!],
    );
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        _travel = (width - knob - pad * 2).clamp(1.0, 10000.0);
        return GestureDetector(
          onHorizontalDragUpdate: _onDrag,
          onHorizontalDragEnd: _onEnd,
          onTap: enabled && !_busy
              ? () async {
                  await _pos.animateTo(0.14, duration: const Duration(milliseconds: 160));
                  await _pos.animateTo(0, curve: Curves.easeOutBack);
                }
              : null,
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[_pos, _shimmer, _spin]),
            builder: (context, _) {
              final v = _pos.value;
              final left = pad + v * _travel;
              final labelOpacity = _busy ? 0.0 : (1 - v * 1.6).clamp(0.0, 1.0);
              return Container(
                height: h,
                decoration: BoxDecoration(
                  gradient: track,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: enabled
                      ? const <BoxShadow>[BoxShadow(color: Color(0x2E1C1726), blurRadius: 26, offset: Offset(0, 12))]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Stack(
                    children: <Widget>[
                      if (enabled && (v > 0 || _busy))
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: _busy ? width : left + knob + pad,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: _busy ? p.slide : fill,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.only(left: knob + pad * 3, right: pad * 3),
                          child: Center(
                            child: Opacity(
                              opacity: labelOpacity,
                              child: _Shimmer(
                                t: _shimmer.value,
                                enabled: enabled,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Flexible(
                                      child: Text(
                                        widget.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: context.sp(15),
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: context.sp(6)),
                                    Text(
                                      '»',
                                      style: TextStyle(color: Colors.white, fontSize: context.sp(15), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_busy)
                        Positioned.fill(
                          child: Padding(
                            padding: EdgeInsets.only(left: context.sp(26), right: knob + pad * 3),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                widget.busyLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white, fontSize: context.sp(15), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        left: left,
                        top: pad,
                        child: Container(
                          width: knob,
                          height: knob,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: enabled ? const Color(0x40000000) : const Color(0x1A000000),
                                blurRadius: _dragging ? 16.0 : 10.0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _busy
                              ? Transform.rotate(
                                  angle: _spin.value * 6.283185307179586,
                                  child: SizedBox(
                                    width: knob * 0.44,
                                    height: knob * 0.44,
                                    child: CircularProgressIndicator(
                                      value: 0.72,
                                      strokeWidth: 2.6,
                                      color: p.accent,
                                      backgroundColor: AppColors.lavender,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.arrow_forward_rounded,
                                  size: knob * 0.46,
                                  color: enabled ? p.accent : const Color(0xFFB3ADBF),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.t, required this.enabled, required this.child});

  final double t;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(Color(0xFFB3ADBF), BlendMode.srcIn),
        child: child,
      );
    }
    final x = -2.2 + t * 4.4;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment(x - 1, 0),
        end: Alignment(x + 1, 0),
        colors: const <Color>[Color(0x8CFFFFFF), Color(0xFFFFFFFF), Color(0x8CFFFFFF)],
        stops: const <double>[0.2, 0.5, 0.8],
        tileMode: TileMode.clamp,
      ).createShader(rect),
      child: child,
    );
  }
}
