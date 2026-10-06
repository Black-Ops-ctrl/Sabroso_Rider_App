import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/scale.dart';
import '../../../widgets/toast.dart';
import '../../../widgets/ui.dart';
import '../orders_provider.dart';

class CancelSheet extends StatefulWidget {
  const CancelSheet({super.key, required this.order});

  final RiderOrder order;

  static Future<bool?> show(BuildContext context, RiderOrder order) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x661C1726),
      builder: (_) => CancelSheet(order: order),
    );
  }

  @override
  State<CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<CancelSheet> {
  final TextEditingController _reason = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _reason.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final text = _reason.text.trim();
    if (text.isEmpty) {
      Toast.error('Enter the reason to cancel');
      _focus.requestFocus();
      return;
    }
    setState(() => _busy = true);
    final r = await context.read<OrdersProvider>().cancel(widget.order, text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.message.isNotEmpty) Toast.result(r.ok, r.message);
    if (r.ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final o = widget.order;
    final sub = <String>[o.customer.name, o.customer.address].where((s) => s.isNotEmpty).join(' · ');
    final radius = BorderRadius.circular(context.sp(14));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(context.sp(26))),
        ),
        padding: EdgeInsets.fromLTRB(context.sp(20), context.sp(10), context.sp(20), context.bottomInset + context.sp(18)),
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
              SizedBox(height: context.sp(18)),
              Row(
                children: <Widget>[
                  IconTile(icon: Icons.close_rounded, color: p.cancel, background: AppColors.cancelledSoft),
                  SizedBox(width: context.sp(14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Cancel ${o.code}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: p.text, fontSize: context.sp(16), fontWeight: FontWeight.w700),
                        ),
                        if (sub.isNotEmpty)
                          Text(
                            sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: p.muted, fontSize: context.sp(12.5)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.sp(20)),
              Text(
                'REASON',
                style: TextStyle(color: _focus.hasFocus ? p.accent : p.muted, fontSize: context.sp(11), letterSpacing: 2),
              ),
              SizedBox(height: context.sp(8)),
              TextField(
                controller: _reason,
                focusNode: _focus,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                style: TextStyle(color: p.text, fontSize: context.sp(14)),
                decoration: InputDecoration(
                  hintText: 'Enter reason',
                  counterText: '',
                  hintStyle: TextStyle(color: const Color(0xFFB3ADBF), fontSize: context.sp(14)),
                  contentPadding: EdgeInsets.all(context.sp(14)),
                  enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: p.accent, width: 1.5)),
                  border: OutlineInputBorder(borderRadius: radius),
                ),
              ),
              SizedBox(height: context.sp(18)),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: GradientButton(
                      label: 'Keep order',
                      gradient: const LinearGradient(colors: <Color>[Color(0xFFF1EEF6), Color(0xFFF1EEF6)]),
                      textColor: p.text,
                      onTap: _busy ? null : () => Navigator.of(context).pop(false),
                    ),
                  ),
                  SizedBox(width: context.sp(12)),
                  Expanded(
                    flex: 3,
                    child: GradientButton(
                      label: 'Cancel order',
                      gradient: p.cancelButton,
                      busy: _busy,
                      shadowColor: fade(p.cancel, 0.3),
                      onTap: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
