import 'package:pick_my_snacks/src/data/model/save_order.dart';

abstract interface class OrderRepository {
  Future<SaveOrderResponse> saveOrder(SaveOrderRequest request);
}
