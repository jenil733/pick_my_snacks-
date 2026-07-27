import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/core/services/local_storage.dart';
import 'package:pick_my_snacks/src/data/model/post_login.dart';
import 'package:pick_my_snacks/src/domain/repository/login_repository.dart';

class LoginRepositoryImpl implements LoginRepository {
  const LoginRepositoryImpl(this._apiService, this._storage);

  final ApiService _apiService;
  final LocalStorageService _storage;

  @override
  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    final json = await _apiService.post(
      ApiRoutes.login,
      data: {'login_id': username, 'password': password},
    );
    final response = LoginResponse.fromJson(json);
    final token = response.data?.token;

    if (response.status == true && token != null && token.isNotEmpty) {
      await _storage.setString(ApiService.authTokenKey, token);
    }

    return response;
  }
}
