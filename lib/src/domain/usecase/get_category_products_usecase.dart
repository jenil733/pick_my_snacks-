import 'package:pick_my_snacks/src/data/model/get_product.dart';
import 'package:pick_my_snacks/src/domain/repository/category_repository.dart';

class GetCategoryProductsUseCase {
  const GetCategoryProductsUseCase(this._repository);
  final CategoryRepository _repository;
  Future<GetProductResponse> call(int categoryId) =>
      _repository.getCategoryProducts(categoryId);
}
