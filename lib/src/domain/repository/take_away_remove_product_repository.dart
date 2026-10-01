import 'package:pick_my_snacks/src/data/model/remove_kot_product.dart';

abstract interface class TakeAwayRemoveProductRepository {
  Future<RemoveKotProductResponse> removeTakeAwayProduct(
    RemoveKotProductRequest request,
  );
}
