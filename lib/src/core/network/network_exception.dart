sealed class NetworkException implements Exception {
  const NetworkException({required this.message, this.code});

  final String message;
  final int? code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkException &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ code.hashCode;

  @override
  String toString() => 'NetworkException(message: $message, code: $code)';
}

class ServerException extends NetworkException {
  const ServerException({required super.message, super.code});
}

class UnauthorisedException extends NetworkException {
  const UnauthorisedException({required super.message, super.code});
}

class BadRequestException extends NetworkException {
  const BadRequestException({required super.message, super.code});
}

class NoInternetException extends NetworkException {
  const NoInternetException({required super.message, super.code});
}

class UnknownNetworkException extends NetworkException {
  const UnknownNetworkException({required super.message, super.code});
}
