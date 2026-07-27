import 'package:get/get.dart';
import 'package:pick_my_snacks/src/data/model/post_login.dart';
import 'package:pick_my_snacks/src/domain/usecase/login_usecase.dart';

class LoginController extends GetxController {
  LoginController(this._loginUseCase);

  final LoginUseCase _loginUseCase;

  final isLoading = false.obs;
  final errorMessage = RxnString();
  final loginData = Rxn<LoginData>();

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    if (isLoading.value) return false;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final response = await _loginUseCase(
        username: username.trim(),
        password: password,
      );
      final isSuccessful = response.status == true;

      if (!isSuccessful) {
        errorMessage.value = response.message ?? 'Unable to log in.';
        return false;
      }

      loginData.value = response.data;
      return true;
    } catch (_) {
      errorMessage.value = 'Unable to log in. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
