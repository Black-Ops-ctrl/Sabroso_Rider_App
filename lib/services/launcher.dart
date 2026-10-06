import 'package:url_launcher/url_launcher.dart';

class Launcher {
  static Future<bool> call(String phone) async {
    final number = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (number.isEmpty) return false;
    try {
      return await launchUrl(Uri(scheme: 'tel', path: number));
    } catch (_) {
      return false;
    }
  }

  static Future<bool> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || url.isEmpty) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> directions({double? lat, double? lng, String address = ''}) {
    final String destination;
    if (lat != null && lng != null) {
      destination = '$lat,$lng';
    } else if (address.trim().isNotEmpty) {
      destination = Uri.encodeComponent(address.trim());
    } else {
      return Future<bool>.value(false);
    }
    return open('https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving');
  }
}
