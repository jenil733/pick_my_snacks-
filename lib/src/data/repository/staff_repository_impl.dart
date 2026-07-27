import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/get_staff.dart';
import 'package:pick_my_snacks/src/domain/repository/staff_repository.dart';

class StaffRepositoryImpl implements StaffRepository {
  const StaffRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<StaffListResponse> getStaff() async {
    final response = await _apiService.get(ApiRoutes.staff);
    return StaffListResponse.fromJson(response);
  }
}
