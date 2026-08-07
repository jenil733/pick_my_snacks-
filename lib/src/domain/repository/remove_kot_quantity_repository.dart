import 'package:pick_my_snacks/src/data/model/remove_kot_quantity.dart';

abstract interface class RemoveKotQuantityRepository {
  Future<RemoveKotQuantityResponse> removeKotQuantity(
    RemoveKotQuantityRequest request,
  );
}
