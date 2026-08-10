import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart' hide ResponseDecoder;
import 'package:flutter/foundation.dart';

import 'logging_interceptor.dart';
import 'network_client.dart';
import 'network_exception.dart';
import 'network_typedefs.dart';
import 'token_storage.dart';

/// Talks to the real TruDeals Realty CRM API.
class DioNetworkClient implements NetworkClient {
  static const String baseUrl = 'https://crm.trudealsrealty.com';

  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Fired when a request that WAS carrying a bearer token comes back 401 —
  /// i.e. the session actually expired/was revoked, as opposed to a 401 on
  /// an unauthenticated request like a failed login attempt. The app wires
  /// this to force a clean logout instead of leaving every screen to fail
  /// independently with "Not signed in" errors.
  void Function()? onUnauthorized;

  DioNetworkClient(this._tokenStorage)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.read();
        options.extra['hadToken'] = token != null;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final hadToken = error.requestOptions.extra['hadToken'] == true;
        if (hadToken && error.response?.statusCode == 401) {
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
    // Added after the auth interceptor so the Authorization header it
    // attaches is present (and redacted) in the logged request.
    _dio.interceptors.add(LoggingInterceptor());
  }

  @override
  Future<NetworkResult<T>> get<T>({
    required String path,
    Json? queryParameters,
    Json? headers,
    ResponseDecoder<T>? decoder,
    CancelToken? cancelToken,
  }) => _request(
        () => _dio.get(path, queryParameters: _clean(queryParameters), options: Options(headers: headers), cancelToken: cancelToken),
        decoder,
      );

  @override
  Future<NetworkResult<T>> post<T>({
    required String path,
    Object? data,
    Json? queryParameters,
    Json? headers,
    ResponseDecoder<T>? decoder,
    CancelToken? cancelToken,
  }) => _request(
        () => _dio.post(path, data: data, queryParameters: _clean(queryParameters), options: Options(headers: headers), cancelToken: cancelToken),
        decoder,
      );

  @override
  Future<NetworkResult<T>> put<T>({
    required String path,
    Object? data,
    Json? queryParameters,
    Json? headers,
    ResponseDecoder<T>? decoder,
    CancelToken? cancelToken,
  }) => _request(
        () => _dio.put(path, data: data, queryParameters: _clean(queryParameters), options: Options(headers: headers), cancelToken: cancelToken),
        decoder,
      );

  @override
  Future<NetworkResult<T>> patch<T>({
    required String path,
    Object? data,
    Json? queryParameters,
    Json? headers,
    ResponseDecoder<T>? decoder,
    CancelToken? cancelToken,
  }) => _request(
        () => _dio.patch(path, data: data, queryParameters: _clean(queryParameters), options: Options(headers: headers), cancelToken: cancelToken),
        decoder,
      );

  @override
  Future<NetworkResult<T>> delete<T>({
    required String path,
    Object? data,
    Json? queryParameters,
    Json? headers,
    ResponseDecoder<T>? decoder,
    CancelToken? cancelToken,
  }) => _request(
        () => _dio.delete(path, data: data, queryParameters: _clean(queryParameters), options: Options(headers: headers), cancelToken: cancelToken),
        decoder,
      );

  @override
  void close({bool force = false}) => _dio.close(force: force);

  /// Drops null query values so they aren't sent as literal "null" strings.
  Map<String, dynamic>? _clean(Json? params) {
    if (params == null) return null;
    final cleaned = <String, dynamic>{};
    params.forEach((k, v) {
      if (v != null && v != '') cleaned[k] = v;
    });
    return cleaned.isEmpty ? null : cleaned;
  }

  Future<NetworkResult<T>> _request<T>(
    Future<Response> Function() call,
    ResponseDecoder<T>? decoder,
  ) async {
    try {
      final response = await call();
      final data = response.data;
      return Right(decoder != null ? decoder(data) : data as T);
    } on DioException catch (e) {
      return Left(_mapError(e));
    } catch (e, stack) {
      debugPrint('DioNetworkClient decode error: $e\n$stack');
      return Left(UnknownNetworkException(message: e.toString()));
    }
  }

  NetworkException _mapError(DioException e) {
    final status = e.response?.statusCode;
    final serverMessage = _extractMessage(e.response?.data);

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NoInternetException(message: serverMessage ?? 'No internet connection', code: status);
      case DioExceptionType.cancel:
        return UnknownNetworkException(message: 'Request cancelled', code: status);
      case DioExceptionType.badResponse:
        if (status == 401) {
          return UnauthorisedException(message: serverMessage ?? 'Not signed in', code: status);
        }
        if (status == 403) {
          return UnauthorisedException(message: serverMessage ?? "You don't have permission to do that", code: status);
        }
        if (status != null && status >= 500) {
          return ServerException(message: serverMessage ?? 'Server error', code: status);
        }
        return BadRequestException(message: serverMessage ?? 'Request failed', code: status);
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
      case DioExceptionType.transformTimeout:
        return UnknownNetworkException(message: serverMessage ?? e.message ?? 'Unknown network error', code: status);
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is Map && data['error'] is String) return data['error'] as String;
    return null;
  }
}
