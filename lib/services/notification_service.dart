import '../core/api.dart';

abstract class PushTokenSource {
  Future<String?> token();
}

class NoPushTokenSource implements PushTokenSource {
  const NoPushTokenSource();

  @override
  Future<String?> token() async => null;
}

class NotificationService {
  NotificationService(this.api, {PushTokenSource? source}) : source = source ?? const NoPushTokenSource();

  final Api api;
  final PushTokenSource source;

  Future<void> register() async {
    try {
      final t = await source.token();
      if (t == null || t.isEmpty) return;
      await sendToken(t);
    } catch (_) {}
  }

  Future<void> sendToken(String token) async {
    if (!api.hasToken) return;
    try {
      await api.post('/rider/fcm-token', <String, dynamic>{'token': token});
    } catch (_) {}
  }
}
