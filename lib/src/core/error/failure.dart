abstract class Failure {
  final String message;
  Failure(this.message);
}

class ServerFailure extends Failure {
  ServerFailure({required String message}) : super(message);
}

class CacheFailure extends Failure {
  CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  NetworkFailure(super.message);
}

class AuthFailure extends Failure {
  AuthFailure(super.message);
}

class UnexpectedFailure extends Failure {
  UnexpectedFailure(super.message);
}
