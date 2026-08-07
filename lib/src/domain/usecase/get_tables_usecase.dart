import 'package:pick_my_snacks/src/data/model/get_table.dart';
import 'package:pick_my_snacks/src/domain/repository/table_repository.dart';

class GetTablesUseCase {
  const GetTablesUseCase(this._repository);

  final TableRepository _repository;

  Future<TableListResponse> call() => _repository.getTables();
}
