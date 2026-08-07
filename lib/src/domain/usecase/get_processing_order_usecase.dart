import 'package:pick_my_snacks/src/data/model/processing.dart';
import 'package:pick_my_snacks/src/domain/repository/processing_order_repository.dart';

class GetProcessingOrderUseCase {
  const GetProcessingOrderUseCase(this._repository);

  final ProcessingOrderRepository _repository;

  Future<ProcessingOrderResponse> call(int tableId) {
    return _repository.getProcessingOrder(tableId);
  }
}
