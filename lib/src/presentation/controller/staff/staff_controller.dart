import 'dart:async';

import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/services/local_storage.dart';
import 'package:pick_my_snacks/src/data/model/get_staff.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_staff_usecase.dart';

class StaffController extends GetxController {
  StaffController([this._getStaffUseCase, this._storage]);

  final GetStaffUseCase? _getStaffUseCase;
  final LocalStorageService? _storage;

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

  @override
  void onInit() {
    super.onInit();
    if (_getStaffUseCase != null) {
      unawaited(getStaff());
    }
  }

  Future<void> selectStaff(StaffData value) async {
    selectedStaff.value = value;
    final id = value.id;
    if (_storage != null && id != null) {
      await _storage.setInt(LocalStorageService.selectedStaffIdKey, id);
    }
  }

  Future<void> getStaff() async {
    if (isLoading.value) return;

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
      await _restoreSelectedStaff();
    } catch (_) {
      staff.clear();
      errorMessage.value = 'Unable to load staff. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _restoreSelectedStaff() async {
    final storage = _storage;
    if (storage == null || selectedStaff.value != null) return;

    final savedId = storage.getInt(LocalStorageService.selectedStaffIdKey);
    if (savedId == null) return;

    final matches = staff.where((item) => item.id == savedId);
    if (matches.isNotEmpty) {
      selectedStaff.value = matches.first;
    } else {
      await storage.remove(LocalStorageService.selectedStaffIdKey);
    }
  }

  Future<void> clearSelection() async {
    selectedStaff.value = null;
    await _storage?.remove(LocalStorageService.selectedStaffIdKey);
  }
}
