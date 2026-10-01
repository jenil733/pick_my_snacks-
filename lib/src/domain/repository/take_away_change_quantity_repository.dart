import 'package:pick_my_snacks/src/data/model/take_away_change_quantity.dart';

abstract interface class TakeAwayChangeQuantityRepository {
  Future<TakeAwayChangeQuantityResponse> changeTakeAwayQuantity(
    TakeAwayChangeQuantityRequest request,
  );
}
