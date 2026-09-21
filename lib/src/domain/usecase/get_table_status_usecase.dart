import 'package:pick_my_snacks/src/data/model/get_table_status.dart';
import 'package:pick_my_snacks/src/domain/repository/table_status_repository.dart';

class GetTableStatusUseCase {
  const GetTableStatusUseCase(this._repository);

  final TableStatusRepository _repository;

  Future<TableStatusResponse> call({
    int? staffId,
    required String paymentMode,
    List<int> productIds = const <int>[1],
  }) => _repository.getTableStatuses(
    staffId: staffId,
    paymentMode: paymentMode,
    productIds: productIds,
  );
}
