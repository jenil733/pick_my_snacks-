import 'package:pick_my_snacks/src/data/model/get_product.dart';
import 'package:pick_my_snacks/src/data/model/get_category.dart';

abstract class CategoryRepository {
  Future<CategoryResponse> getCategories();
  Future<GetProductResponse> getCategoryProducts(int categoryId);
}
