import 'package:pick_my_snacks/src/data/model/post_kot_model.dart';

abstract interface class KotOrderRepository {
  Future<KotOrderResponse> saveKotOrder(KotOrderRequest request);
}
