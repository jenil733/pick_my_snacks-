import 'package:pick_my_snacks/src/data/model/get_saveorder.dart';

abstract interface class KotSaveRepository {
  Future<KotSaveResponse> saveKot(int tableId);
}
