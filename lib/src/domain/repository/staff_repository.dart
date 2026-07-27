import 'package:pick_my_snacks/src/data/model/get_staff.dart';

abstract interface class StaffRepository {
  Future<StaffListResponse> getStaff();
}
