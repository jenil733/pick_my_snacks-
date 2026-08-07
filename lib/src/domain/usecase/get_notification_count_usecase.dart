import 'package:pick_my_snacks/src/data/model/get_product.dart';
import 'package:pick_my_snacks/src/domain/repository/product_repository.dart';

class GetNotificationCountUseCase {
  const GetNotificationCountUseCase(this._repository);

  final ProductRepository _repository;

  Future<NotificationCountResponse> call() =>
      _repository.getNotificationCount();
}
