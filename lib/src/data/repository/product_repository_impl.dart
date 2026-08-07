import 'package:flutter/foundation.dart';
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

  @override
  Future<LowStockProductsResponse> getLowStockProducts() async {
    debugPrint('[LowStockAPI] GET ${ApiRoutes.lowStockProducts}');
    final response = await _apiService.get(ApiRoutes.lowStockProducts);
    debugPrint('[LowStockAPI] Response: $response');
    return LowStockProductsResponse.fromJson(response);
  }

  @override
  Future<OutOfStockProductsResponse> getOutOfStockProducts() async {
    debugPrint('[OutOfStockAPI] GET ${ApiRoutes.outOfStockProducts}');
    final response = await _apiService.get(ApiRoutes.outOfStockProducts);
    debugPrint('[OutOfStockAPI] Response: $response');
    return OutOfStockProductsResponse.fromJson(response);
  }

  @override
  Future<NotificationCountResponse> getNotificationCount() async {
    debugPrint('[NotificationCountAPI] GET ${ApiRoutes.notificationCount}');
    final response = await _apiService.get(ApiRoutes.notificationCount);
    debugPrint('[NotificationCountAPI] Response: $response');
    return NotificationCountResponse.fromJson(response);
  }
}
