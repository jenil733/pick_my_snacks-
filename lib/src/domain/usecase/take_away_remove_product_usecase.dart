import 'package:pick_my_snacks/src/data/model/remove_kot_product.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_remove_product_repository.dart';

class TakeAwayRemoveProductUseCase {
  const TakeAwayRemoveProductUseCase(this._repository);

  final TakeAwayRemoveProductRepository _repository;

  Future<RemoveKotProductResponse> call(RemoveKotProductRequest request) {
    return _repository.removeTakeAwayProduct(request);
  }
}
