import 'package:pick_my_snacks/src/data/model/get_saveorder.dart';
import 'package:pick_my_snacks/src/data/model/kot_save_request.dart';

abstract interface class KotSaveRepository {
  Future<KotSaveResponse> saveKot(KotSaveRequest request);
}
