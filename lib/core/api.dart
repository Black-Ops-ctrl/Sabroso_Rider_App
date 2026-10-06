import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'config.dart';

class ApiException implements Exception {
  ApiException(this.message, this.status, [this.code]);

  final String message;
  final int status;
  final String? code;

  bool get offline => status == 0;
  bool get noInternet => code == 'NO_INTERNET';
  bool get timeout => code == 'TIMEOUT';
  bool get signedOut => status == 401 && code == 'SIGNED_OUT';
  bool get orderGone => code == 'ORDER_GONE';
  bool get pendingOrders => code == 'PENDING_ORDERS';
  bool get meaningful => offline || status == 400 || status == 403 || status == 404 || status == 409;

  String or(String fallback) => meaningful ? message : fallback;

  @override
  String toString() => message;
}

class Api {
  Api({this.token});

  static const String noInternet = 'No internet. Check your connection';
  static const String noResponse = 'Server is not responding. Try again';
  static const String noServer = "Can't reach the server. Try again";
  static const String noSecure = 'Secure connection failed. Try again';
  static const String serverError = 'Server error. Try again';

  static void Function()? onSignedOut;

  String? token;
  final http.Client _client = http.Client();

  bool get hasToken => (token ?? '').isNotEmpty;

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) => _send('POST', path, body ?? const <String, dynamic>{});
  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) => _send('PATCH', path, body ?? const <String, dynamic>{});

  Future<dynamic> _send(String method, String path, [Map<String, dynamic>? body]) async {
    final request = http.Request(method, Uri.parse('${AppConfig.apiBase}$path'));
    request.headers['Accept'] = 'application/json';
    request.headers['Content-Type'] = 'application/json';
    final sentToken = token;
    if (sentToken != null && sentToken.isNotEmpty) request.headers['Authorization'] = 'Bearer $sentToken';
    if (body != null) request.body = jsonEncode(body);

    http.Response res;
    try {
      final streamed = await _client.send(request).timeout(AppConfig.requestTimeout);
      res = await http.Response.fromStream(streamed).timeout(AppConfig.requestTimeout);
    } on TimeoutException catch (e) {
      debugPrint('API TIMEOUT $method ${request.url}: $e');
      throw ApiException(noResponse, 0, 'TIMEOUT');
    } on HandshakeException catch (e) {
      debugPrint('API HANDSHAKE $method ${request.url}: $e');
      throw ApiException(noSecure, 0, 'HANDSHAKE_ERROR');
    } on SocketException catch (e) {
      debugPrint('API SOCKET $method ${request.url}: $e');
      throw await _networkError();
    } on http.ClientException catch (e) {
      debugPrint('API CLIENT $method ${request.url}: $e');
      throw await _networkError();
    }

    if (res.statusCode >= 500) {
      debugPrint('API ${res.statusCode} $method ${request.url}');
    }

    Map<String, dynamic> json = <String, dynamic>{};
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {}

    if (res.statusCode >= 400 || json['success'] == false) {
      final msg = (json['error'] ?? json['message'] ?? (res.statusCode >= 500 ? serverError : 'Something went wrong. Try again')).toString();
      final e = ApiException(msg, res.statusCode, json['code']?.toString());
      if (e.signedOut && sentToken != null && sentToken.isNotEmpty && sentToken == token) {
        final handler = onSignedOut;
        if (handler != null) handler();
      }
      throw e;
    }
    return json.containsKey('data') ? json['data'] : json;
  }

  static Future<bool> _hasInternet() async {
    try {
      final r = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 3));
      return r.isNotEmpty && r.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<ApiException> _networkError() async {
    if (await _hasInternet()) return ApiException(noServer, 0, 'SERVER_UNREACHABLE');
    return ApiException(noInternet, 0, 'NO_INTERNET');
  }

  void close() => _client.close();
}
