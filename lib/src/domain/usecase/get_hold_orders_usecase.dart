import 'package:pick_my_snacks/src/data/model/get_hold.dart';
import 'package:pick_my_snacks/src/domain/repository/get_hold_orders_repository.dart';

class GetHoldOrdersUseCase {
  const GetHoldOrdersUseCase(this._repository);

  final GetHoldOrdersRepository _repository;

  Future<GetHoldOrdersResponse> call() => _repository.getHoldOrders();
}
