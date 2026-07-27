import 'package:pick_my_snacks/src/data/model/get_delete.dart';

abstract interface class DeleteHeldBillRepository {
  Future<DeleteHeldBillResponse> deleteHeldBill(int orderId);
}
