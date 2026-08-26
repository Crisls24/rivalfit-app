sealed class Failure {
  final String message;
  const Failure({required this.message});
}

class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Error del servidor'});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Sin conexion a internet'});
}

class AuthFailure extends Failure {
  const AuthFailure({super.message = 'Error de autenticacion'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Error de cache'});
}
