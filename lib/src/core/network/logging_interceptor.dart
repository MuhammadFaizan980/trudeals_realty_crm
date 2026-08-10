import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Debug-only request/response logging for the API client — full URL,
/// request body, and server response body, unmodified except for redacting
/// credentials.
///
/// Deliberately does nothing in release builds (checked per-call, not just
/// at registration, so there's no risk of it slipping into a release build
/// via some other flag). Redacts the `Authorization` header and any
/// `password` fields in request bodies — even in debug builds, this output
/// can end up in a shared terminal, screen recording, or bug report, and a
/// raw bearer token or password has no business being there. Everything
/// else is printed exactly as sent/received, unabridged.
class LoggingInterceptor extends Interceptor {
  static const _redacted = '••••••';
  static const _sensitiveKeys = {'password', 'authorization'};
  static const _startedAtKey = '__loggingInterceptorStartedAt';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      options.extra[_startedAtKey] = DateTime.now();
      final headers = _redactShallow(options.headers);
      final buffer = StringBuffer('→ ${options.method} ${options.uri}');
      if (headers.isNotEmpty) buffer.write('\n   headers: $headers');
      if (options.data != null) buffer.write('\n   body: ${_format(_redactBody(options.data))}');
      _print(buffer.toString());
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final buffer = StringBuffer(
        '← ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}'
        ' (${_elapsedMs(response.requestOptions)})',
      );
      if (response.data != null) buffer.write('\n   response: ${_format(response.data)}');
      _print(buffer.toString());
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final buffer = StringBuffer(
        '✗ ${err.response?.statusCode ?? err.type} ${err.requestOptions.method} ${err.requestOptions.uri}'
        ' (${_elapsedMs(err.requestOptions)}) — ${err.message}',
      );
      if (err.response?.data != null) buffer.write('\n   response: ${_format(err.response!.data)}');
      _print(buffer.toString());
    }
    handler.next(err);
  }

  String _elapsedMs(RequestOptions options) {
    final startedAt = options.extra[_startedAtKey] as DateTime?;
    if (startedAt == null) return '?ms';
    return '${DateTime.now().difference(startedAt).inMilliseconds}ms';
  }

  Map<String, dynamic> _redactShallow(Map<String, dynamic> map) {
    return map.map((k, v) => MapEntry(k, _sensitiveKeys.contains(k.toLowerCase()) ? _redacted : v));
  }

  dynamic _redactBody(dynamic data) {
    if (data is Map) {
      return data.map((k, v) => MapEntry(k, _sensitiveKeys.contains(k.toString().toLowerCase()) ? _redacted : _redactBody(v)));
    }
    return data;
  }

  /// Pretty-prints JSON-like bodies; falls back to the raw value for
  /// anything that isn't (form data, plain strings, etc).
  String _format(dynamic data) {
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  /// debugPrint truncates any single call around ~1024 chars on Android
  /// logcat / some consoles — split long output into safe-sized chunks so
  /// nothing gets cut off. This is purely about print-call size, not about
  /// hiding or shortening content.
  void _print(String message) {
    const chunkSize = 900;
    if (message.length <= chunkSize) {
      debugPrint(message);
      return;
    }
    for (var i = 0; i < message.length; i += chunkSize) {
      debugPrint(message.substring(i, i + chunkSize > message.length ? message.length : i + chunkSize));
    }
  }
}
