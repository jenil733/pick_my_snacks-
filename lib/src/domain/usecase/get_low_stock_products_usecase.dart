import 'package:pick_my_snacks/src/data/model/get_product.dart';
import 'package:pick_my_snacks/src/domain/repository/product_repository.dart';

class GetLowStockProductsUseCase {
  const GetLowStockProductsUseCase(this._repository);

  final ProductRepository _repository;

  Future<LowStockProductsResponse> call() => _repository.getLowStockProducts();
}
