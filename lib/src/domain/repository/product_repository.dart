import 'package:pick_my_snacks/src/data/model/get_product.dart';

abstract interface class ProductRepository {
  Future<GetProductResponse> getProducts();
}
