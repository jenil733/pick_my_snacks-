import 'package:pick_my_snacks/src/data/model/get_hold.dart';

abstract interface class GetHoldOrdersRepository {
  Future<GetHoldOrdersResponse> getHoldOrders();
}
