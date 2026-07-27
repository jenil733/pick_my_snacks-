import 'package:pick_my_snacks/src/data/model/get_delete.dart';
import 'package:pick_my_snacks/src/domain/repository/delete_held_bill_repository.dart';

class DeleteHeldBillUseCase {
  const DeleteHeldBillUseCase(this._repository);

  final DeleteHeldBillRepository _repository;

  Future<DeleteHeldBillResponse> call(int orderId) {
    return _repository.deleteHeldBill(orderId);
  }
}
