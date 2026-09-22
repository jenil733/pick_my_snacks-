import 'package:pick_my_snacks/src/data/model/get_product.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/get_category.dart';
import 'package:pick_my_snacks/src/domain/repository/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl(this._apiService);
  final ApiService _apiService;

  @override
  Future<CategoryResponse> getCategories() async =>
      CategoryResponse.fromJson(await _apiService.get(ApiRoutes.categories));
  @override
  Future<GetProductResponse> getCategoryProducts(int categoryId) async {
    final json = await _apiService.get(ApiRoutes.categoryProducts(categoryId));
    if (json['success'] != false && json['data'] is! List) {
      throw const FormatException('Invalid category products response');
    }
    return GetProductResponse.fromJson(json);
  }
}
