import 'package:pick_my_snacks/src/data/model/remove_kot_product.dart';

abstract interface class RemoveKotProductRepository {
  Future<RemoveKotProductResponse> removeKotProduct(
    RemoveKotProductRequest request,
  );
}
