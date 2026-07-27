import 'package:pick_my_snacks/src/data/model/hold_order.dart';
import 'package:pick_my_snacks/src/domain/repository/hold_order_repository.dart';

class HoldOrderUseCase {
  const HoldOrderUseCase(this._repository);

  final HoldOrderRepository _repository;

  Future<HoldOrderResponse> call(HoldOrderRequest request) {
    return _repository.holdOrder(request);
  }
}
