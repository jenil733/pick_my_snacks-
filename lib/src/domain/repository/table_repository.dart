import 'package:pick_my_snacks/src/data/model/get_table.dart';

abstract interface class TableRepository {
  Future<TableListResponse> getTables();
}
