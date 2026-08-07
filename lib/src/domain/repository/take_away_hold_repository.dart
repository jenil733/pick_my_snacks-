import 'package:pick_my_snacks/src/data/model/take_away_hold.dart';

abstract interface class TakeAwayHoldRepository {
  Future<TakeAwayHoldResponse> holdTakeAway(TakeAwayHoldRequest request);
}
