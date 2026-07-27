import 'package:pick_my_snacks/src/data/model/save_order.dart';
import 'package:pick_my_snacks/src/domain/repository/order_repository.dart';

class SaveOrderUseCase {
  const SaveOrderUseCase(this._repository);

  final OrderRepository _repository;

  Future<SaveOrderResponse> call(SaveOrderRequest request) {
    return _repository.saveOrder(request);
  }
}
