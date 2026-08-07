import 'package:pick_my_snacks/src/data/model/take_away_save_order.dart';

abstract interface class TakeAwaySaveOrderRepository {
  Future<TakeAwaySaveOrderResponse> saveTakeAwayOrder(
    TakeAwaySaveOrderRequest request,
  );
}
