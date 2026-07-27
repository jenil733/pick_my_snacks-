import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/get_product.dart';
import 'package:pick_my_snacks/src/domain/repository/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<GetProductResponse> getProducts() async {
    final response = await _apiService.get(ApiRoutes.products);
    return GetProductResponse.fromJson(response);
  }
}
