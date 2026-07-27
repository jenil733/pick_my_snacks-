import 'package:pick_my_snacks/src/data/model/post_login.dart';

abstract interface class LoginRepository {
  Future<LoginResponse> login({
    required String username,
    required String password,
  });
}
