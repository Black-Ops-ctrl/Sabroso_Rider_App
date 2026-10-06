import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabroso_rider/core/format.dart';
import 'package:sabroso_rider/core/models.dart';
import 'package:sabroso_rider/core/polyline.dart';
import 'package:sabroso_rider/theme/app_colors.dart';

void main() {
  test('theme keys fall back to defaults', () {
    final c = AppColors.from(<String, String>{'accent': '#10b981', 'cancel': ''});
    expect(c.accent, const Color(0xFF10B981));
    expect(c.cancel, const Color(0xFFDC2626));
    expect(c.headerTop, const Color(0xFF2E0654));
  });

  test('formats money, distance and duration', () {
    expect(Fmt.money(1850), 'Rs 1,850');
    expect(Fmt.km(18.4), '18.4 km');
    expect(Fmt.km(176), '176 km');
    expect(Fmt.km(2.0), '2 km');
    expect(Fmt.duration(320), '5h 20m');
    expect(Fmt.initials('Ali Raza'), 'AR');
  });

  test('decodes a Google polyline', () {
    final pts = decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
    expect(pts.length, 3);
    expect(pts.first.lat, closeTo(38.5, 1e-6));
    expect(pts.first.lng, closeTo(-120.2, 1e-6));
    expect(pts.last.lat, closeTo(43.252, 1e-6));
  });

  test('parses rider order payload', () {
    final o = RiderOrder.fromJson(<String, dynamic>{
      'id': '7',
      'code': 'SB-1',
      'status': 'CANCELLED',
      'total': '600.00',
      'cancelled_by': 'You',
      'customer': <String, dynamic>{'name': 'Sara', 'lat': 31.4, 'lng': '74.3'},
      'items': <dynamic>[
        <String, dynamic>{'name': 'Bucket', 'qty': 2, 'price': 100, 'total': 200},
      ],
    });
    expect(o.id, 7);
    expect(o.total, 600);
    expect(o.cancelledByMe, isTrue);
    expect(o.customer.lng, 74.3);
    expect(o.items.single.qty, 2);
  });
}
