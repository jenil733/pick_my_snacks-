import 'package:pick_my_snacks/src/data/model/get_table_status.dart';

abstract interface class TableStatusRepository {
  Future<TableStatusResponse> getTableStatuses();
}
