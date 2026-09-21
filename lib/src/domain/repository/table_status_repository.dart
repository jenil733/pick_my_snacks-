import 'package:pick_my_snacks/src/data/model/get_table_status.dart';

abstract interface class TableStatusRepository {
  Future<TableStatusResponse> getTableStatuses({
    int? staffId,
    required String paymentMode,
    List<int> productIds = const <int>[1],
  });
}
