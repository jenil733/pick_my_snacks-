import 'package:get/get.dart';
import 'package:pick_my_snacks/src/data/model/get_staff.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_staff_usecase.dart';

class StaffController extends GetxController {
  StaffController([this._getStaffUseCase]);

  final GetStaffUseCase? _getStaffUseCase;

  final staff = <StaffData>[].obs;
  final selectedStaff = Rxn<StaffData>();
  final isLoading = false.obs;
  final errorMessage = RxnString();

  String get selectedStaffId {
    final id = selectedStaff.value?.id;
    return id == null ? 'Staff' : id.toString();
  }

  String get selectedStaffName {
    final name = selectedStaff.value?.name?.trim();
    return name == null || name.isEmpty ? 'Staff' : name;
  }

  void selectStaff(StaffData value) {
    selectedStaff.value = value;
  }

  Future<void> getStaff() async {
    final useCase = _getStaffUseCase;
    if (useCase == null) {
      staff.clear();
      errorMessage.value = null;
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final response = await useCase();
      if (response.status == false) {
        staff.clear();
        errorMessage.value = response.message ?? 'Unable to load staff.';
        return;
      }
      staff.assignAll(response.data ?? const <StaffData>[]);
    } catch (_) {
      staff.clear();
      errorMessage.value = 'Unable to load staff. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }
}
