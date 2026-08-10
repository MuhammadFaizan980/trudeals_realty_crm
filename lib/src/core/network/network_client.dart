import 'package:dio/dio.dart' show CancelToken;
import 'network_typedefs.dart';

abstract interface class NetworkClient {
  Future<NetworkResult<T>> get<T>({
    required String path,
    Json? queryParameters,
    Json? headers,
    ResponseDecoder<T>? decoder,
    CancelToken? cancelToken,
  });

  Future<NetworkResult<T>> post<T>({
    required String path,
    Object? data,
    Json? queryParameters,
    Json? headers,
    ResponseDecoder<T>? decoder,
    CancelToken? cancelToken,
  });

  Future<NetworkResult<T>> put<T>({
    required String path,
    Object? data,
    Json? queryParameters,
    Json? headers,
    ResponseDecoder<T>? decoder,
    CancelToken? cancelToken,
  });

  Future<NetworkResult<T>> patch<T>({
    required String path,
    Object? data,
    Json? queryParameters,
    Json? headers,
    ResponseDecoder<T>? decoder,
    CancelToken? cancelToken,
  });

  Future<NetworkResult<T>> delete<T>({
    required String path,
    Object? data,
    Json? queryParameters,
    Json? headers,
    ResponseDecoder<T>? decoder,
    CancelToken? cancelToken,
  });

  void close({bool force = false});
}
