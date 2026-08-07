import 'package:pick_my_snacks/src/data/model/post_kot_model.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_order_repository.dart';

class SaveKotOrderUseCase {
  const SaveKotOrderUseCase(this._repository);

  final KotOrderRepository _repository;

  Future<KotOrderResponse> call(KotOrderRequest request) {
    return _repository.saveKotOrder(request);
  }
}
