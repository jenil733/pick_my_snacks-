import 'package:pick_my_snacks/src/data/model/hold_order.dart';

abstract interface class HoldOrderRepository {
  Future<HoldOrderResponse> holdOrder(HoldOrderRequest request);
}
