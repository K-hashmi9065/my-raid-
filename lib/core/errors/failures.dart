class Failure {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  String toString() => 'Failure(message: $message, statusCode: $statusCode)';
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection'});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache error'});
}

class AuthFailure extends Failure {
  const AuthFailure({super.message = 'Authentication failed'});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}
