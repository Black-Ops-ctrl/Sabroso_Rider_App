import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class LiveClient {
  LiveClient({required this.token, required this.onChange, this.onUnauthorized});

  final String token;
  final void Function(List<String> tables) onChange;
  final void Function()? onUnauthorized;

  http.Client? _client;
  StreamSubscription<String>? _sub;
  Timer? _retry;
  bool _closed = false;

  void start() {
    _closed = false;
    _connect();
  }

  Future<void> _connect() async {
    if (_closed) return;
    await _sub?.cancel();
    _sub = null;
    _client?.close();
    final client = http.Client();
    _client = client;
    try {
      final uri = Uri.parse('${AppConfig.apiBase}/rider/live?token=${Uri.encodeQueryComponent(token)}');
      final req = http.Request('GET', uri)..headers['Accept'] = 'text/event-stream';
      final res = await client.send(req);
      if (_closed) {
        client.close();
        return;
      }
      if (res.statusCode != 200) {
        if (res.statusCode == 401) {
          final cb = onUnauthorized;
          if (cb != null) cb();
          _schedule(const Duration(seconds: 15));
        } else {
          _schedule(const Duration(seconds: 3));
        }
        return;
      }
      var event = '';
      var data = StringBuffer();
      _sub = res.stream.transform(utf8.decoder).transform(const LineSplitter()).listen(
        (line) {
          if (line.isEmpty) {
            if (event == 'change') {
              try {
                final d = jsonDecode(data.toString());
                final tables = (d is Map && d['tables'] is List)
                    ? (d['tables'] as List).map((e) => e.toString()).toList()
                    : <String>[];
                onChange(tables);
              } catch (_) {
                onChange(const <String>[]);
              }
            }
            event = '';
            data = StringBuffer();
          } else if (line.startsWith('event:')) {
            event = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            data.write(line.substring(5).trim());
          }
        },
        onError: (Object _) => _schedule(const Duration(seconds: 3)),
        onDone: () => _schedule(const Duration(seconds: 3)),
        cancelOnError: true,
      );
    } catch (_) {
      _schedule(const Duration(seconds: 3));
    }
  }

  void _schedule(Duration d) {
    if (_closed) return;
    _retry?.cancel();
    _retry = Timer(d, _connect);
  }

  void stop() {
    _closed = true;
    _retry?.cancel();
    _sub?.cancel();
    _sub = null;
    _client?.close();
    _client = null;
  }
}
