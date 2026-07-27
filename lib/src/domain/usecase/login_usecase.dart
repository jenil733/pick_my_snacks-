import 'package:pick_my_snacks/src/data/model/post_login.dart';
import 'package:pick_my_snacks/src/domain/repository/login_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final LoginRepository _repository;

  Future<LoginResponse> call({
    required String username,
    required String password,
  }) {
    return _repository.login(username: username, password: password);
  }
}
