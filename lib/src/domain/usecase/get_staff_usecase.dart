import 'package:pick_my_snacks/src/data/model/get_staff.dart';
import 'package:pick_my_snacks/src/domain/repository/staff_repository.dart';

class GetStaffUseCase {
  const GetStaffUseCase(this._repository);

  final StaffRepository _repository;

  Future<StaffListResponse> call() => _repository.getStaff();
}
