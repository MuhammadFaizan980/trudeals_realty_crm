import 'package:dart_either/dart_either.dart';
import 'network_exception.dart';

typedef Json = Map<String, dynamic>;
typedef ResponseDecoder<T> = T Function(dynamic data);
typedef NetworkResult<T> = Either<NetworkException, T>;
