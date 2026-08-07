import 'package:pick_my_snacks/src/data/model/take_away_save_order.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_save_order_repository.dart';

class TakeAwaySaveOrderUseCase {
  const TakeAwaySaveOrderUseCase(this._repository);

  final TakeAwaySaveOrderRepository _repository;

  Future<TakeAwaySaveOrderResponse> call(TakeAwaySaveOrderRequest request) {
    return _repository.saveTakeAwayOrder(request);
  }
}
