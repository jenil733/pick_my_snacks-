import 'package:pick_my_snacks/src/data/model/remove_kot_product.dart';
import 'package:pick_my_snacks/src/domain/repository/remove_kot_product_repository.dart';

class RemoveKotProductUseCase {
  const RemoveKotProductUseCase(this._repository);

  final RemoveKotProductRepository _repository;

  Future<RemoveKotProductResponse> call(RemoveKotProductRequest request) {
    return _repository.removeKotProduct(request);
  }
}
