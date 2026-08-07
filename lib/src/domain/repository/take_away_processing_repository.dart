import 'package:pick_my_snacks/src/data/model/take_away_processing.dart';

abstract interface class TakeAwayProcessingRepository {
  Future<TakeAwayProcessingResponse> getProcessingTakeAway([int? holdOrderId]);
}
