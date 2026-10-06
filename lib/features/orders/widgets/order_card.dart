import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/format.dart';
import '../../../core/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/scale.dart';
import '../../../widgets/ui.dart';
import '../order_actions.dart';
import '../orders_provider.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.onOpen});

  final RiderOrder order;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final o = order;
    final meta = <String>[
      if (o.km != null) Fmt.km(o.km),
      if (o.deliveryMin != null && !o.isActive) Fmt.minutes(o.deliveryMin),
    ].join(' · ');
    return AppCard(
      onTap: onOpen,
      padding: EdgeInsets.fromLTRB(context.sp(16), context.sp(14), context.sp(16), context.sp(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        o.code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.text, fontSize: context.sp(15), fontWeight: FontWeight.w700),
                      ),
                    ),
                    SizedBox(width: context.sp(8)),
                    Flexible(
                      child: StatusChip(status: o.status, label: o.statusLabel.isEmpty ? Fmt.titleCase(o.status) : o.statusLabel),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.sp(8)),
              Text(
                Fmt.money(o.total),
                maxLines: 1,
                style: TextStyle(color: p.text, fontSize: context.sp(15), fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: context.sp(4)),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.muted, fontSize: context.sp(12)),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: context.sp(120)),
                child: Text(
                  o.paymentShort,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.muted, fontSize: context.sp(12)),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.sp(12)),
            child: const Divider(height: 1, thickness: 1, color: AppColors.border),
          ),
          Text(
            o.customer.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: p.text, fontSize: context.sp(14.5), fontWeight: FontWeight.w600),
          ),
          if (o.customer.address.isNotEmpty) ...<Widget>[
            SizedBox(height: context.sp(4)),
            Row(
              children: <Widget>[
                Icon(Icons.location_on_outlined, size: context.sp(15), color: p.muted),
                SizedBox(width: context.sp(6)),
                Expanded(
                  child: Text(
                    o.customer.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.text2, fontSize: context.sp(12.5)),
                  ),
                ),
              ],
            ),
          ],
          if (o.isCancelled) ...<Widget>[
            SizedBox(height: context.sp(12)),
            ReasonBox(order: o, compact: true),
          ],
          if (o.isActive) ...<Widget>[
            SizedBox(height: context.sp(14)),
            OrderActionRow(order: o),
          ],
        ],
      ),
    );
  }
}

class ReasonBox extends StatelessWidget {
  const ReasonBox({super.key, required this.order, this.compact = false});

  final RiderOrder order;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final o = order;
    final String title;
    if (compact) {
      title = 'Reason · ${Fmt.time(o.cancelledAt)}';
    } else if (o.cancelledByMe) {
      title = 'Cancelled by you · ${Fmt.time(o.cancelledAt)}';
    } else if (o.cancelledBy.isNotEmpty) {
      title = 'Cancelled by ${o.cancelledBy} · ${Fmt.time(o.cancelledAt)}';
    } else {
      title = 'Cancelled · ${Fmt.time(o.cancelledAt)}';
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.sp(14), vertical: context.sp(12)),
      decoration: BoxDecoration(color: AppColors.cancelledSoft, borderRadius: BorderRadius.circular(context.sp(12))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: p.cancel, fontSize: context.sp(12), fontWeight: FontWeight.w600),
          ),
          if (o.cancelReason.isNotEmpty) ...<Widget>[
            SizedBox(height: context.sp(3)),
            Text(
              o.cancelReason,
              maxLines: compact ? 2 : 6,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.text, fontSize: context.sp(13)),
            ),
          ],
        ],
      ),
    );
  }
}

class OrderActionRow extends StatelessWidget {
  const OrderActionRow({super.key, required this.order});

  final RiderOrder order;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final o = order;
    final busy = context.select<OrdersProvider, bool>((x) => x.busy.contains(o.id));
    final gap = context.sp(10);
    return Row(
      children: <Widget>[
        RoundIconButton(
          icon: Icons.call_outlined,
          color: AppColors.delivered,
          background: AppColors.greenSoft,
          onTap: () => OrderActions.call(o.customer.name, o.customer.phone),
        ),
        SizedBox(width: gap),
        RoundIconButton(
          icon: Icons.navigation_outlined,
          color: p.accent,
          background: AppColors.lavender,
          onTap: () => OrderActions.navigate(o.customer),
        ),
        SizedBox(width: gap),
        RoundIconButton(
          icon: Icons.close_rounded,
          color: p.cancel,
          background: AppColors.cancelledSoft,
          onTap: busy ? null : () => OrderActions.cancel(context, o),
        ),
        SizedBox(width: gap),
        Expanded(
          child: GradientButton(
            label: o.isAssigned ? 'Out for delivery' : 'Delivered',
            gradient: o.isAssigned ? p.ofdButton : p.deliveredButton,
            shadowColor: fade(o.isAssigned ? p.ofdBottom : p.deliveredBottom, 0.3),
            busy: busy,
            onTap: () => OrderActions.advance(context, o),
          ),
        ),
      ],
    );
  }
}
