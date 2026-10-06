import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../theme/app_colors.dart';
import '../../theme/scale.dart';
import '../../widgets/ui.dart';

class DateRangeValue {
  const DateRangeValue(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

class RangePickerSheet extends StatefulWidget {
  const RangePickerSheet({super.key, this.start, this.end});

  final DateTime? start;
  final DateTime? end;

  static Future<DateRangeValue?> show(BuildContext context, {DateTime? start, DateTime? end}) {
    return showModalBottomSheet<DateRangeValue>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x661C1726),
      builder: (_) => RangePickerSheet(start: start, end: end),
    );
  }

  @override
  State<RangePickerSheet> createState() => _RangePickerSheetState();
}

class _RangePickerSheetState extends State<RangePickerSheet> {
  late DateTime _month;
  DateTime? _start;
  DateTime? _end;
  late final DateTime _today;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _start = widget.start;
    _end = widget.end;
    final base = widget.end ?? widget.start ?? _today;
    _month = DateTime(base.year, base.month);
  }

  void _tap(DateTime d) {
    setState(() {
      final s = _start;
      if (s == null || _end != null) {
        _start = d;
        _end = null;
      } else if (d.isBefore(s)) {
        _start = d;
        _end = s;
      } else {
        _end = d;
      }
    });
  }

  void _shift(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    if (next.isAfter(DateTime(_today.year, _today.month))) return;
    setState(() => _month = next);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = <DateTime?>[
      for (var i = 1; i < firstWeekday; i++) null,
      for (var d = 1; d <= days; d++) DateTime(_month.year, _month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final canNext = DateTime(_month.year, _month.month + 1).isBefore(DateTime(_today.year, _today.month + 1));
    final ready = _start != null && _end != null;
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.sp(26))),
      ),
      padding: EdgeInsets.fromLTRB(context.sp(16), context.sp(10), context.sp(16), context.bottomInset + context.sp(16)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: context.sp(40),
                height: context.sp(4),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            SizedBox(height: context.sp(12)),
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => _shift(-1),
                  icon: Icon(Icons.chevron_left_rounded, color: p.muted),
                ),
                Expanded(
                  child: Text(
                    Fmt.monthYear(_month),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.text, fontSize: context.sp(16), fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: canNext ? () => _shift(1) : null,
                  icon: Icon(Icons.chevron_right_rounded, color: canNext ? p.muted : AppColors.border),
                ),
              ],
            ),
            SizedBox(height: context.sp(6)),
            Row(
              children: <Widget>[
                for (final l in const <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                  Expanded(
                    child: Text(
                      l,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.muted, fontSize: context.sp(12)),
                    ),
                  ),
              ],
            ),
            SizedBox(height: context.sp(8)),
            for (var r = 0; r < cells.length ~/ 7; r++)
              Row(
                children: <Widget>[
                  for (var c = 0; c < 7; c++) Expanded(child: _cell(context, cells[r * 7 + c])),
                ],
              ),
            SizedBox(height: context.sp(16)),
            Row(
              children: <Widget>[
                Expanded(
                  child: GradientButton(
                    label: 'Cancel',
                    gradient: const LinearGradient(colors: <Color>[Color(0xFFF1EEF6), Color(0xFFF1EEF6)]),
                    textColor: p.text,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                SizedBox(width: context.sp(12)),
                Expanded(
                  child: GradientButton(
                    label: 'Done',
                    gradient: p.accentButton,
                    onTap: ready ? () => Navigator.of(context).pop(DateRangeValue(_start!, _end!)) : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, DateTime? d) {
    final p = context.palette;
    final h = context.sp(44);
    if (d == null) return SizedBox(height: h);
    final s = _start;
    final e = _end;
    final future = d.isAfter(_today);
    final isStart = s != null && Fmt.sameDay(d, s);
    final isEnd = e != null && Fmt.sameDay(d, e);
    final inRange = s != null && e != null && d.isAfter(s) && d.isBefore(e);
    final selected = isStart || isEnd;
    final band = inRange || (s != null && e != null && (isStart || isEnd) && !Fmt.sameDay(s, e));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: future ? null : () => _tap(d),
      child: SizedBox(
        height: h,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            if (band)
              Positioned(
                left: 0,
                right: 0,
                top: context.sp(4),
                bottom: context.sp(4),
                child: Row(
                  children: <Widget>[
                    Expanded(child: ColoredBox(color: isStart ? Colors.transparent : AppColors.lavender)),
                    Expanded(child: ColoredBox(color: isEnd ? Colors.transparent : AppColors.lavender)),
                  ],
                ),
              ),
            if (selected)
              Container(
                width: h - context.sp(6),
                height: h - context.sp(6),
                decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
              ),
            Text(
              '${d.day}',
              style: TextStyle(
                color: selected ? Colors.white : (future ? const Color(0xFFCFC9DC) : p.text),
                fontSize: context.sp(13.5),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
