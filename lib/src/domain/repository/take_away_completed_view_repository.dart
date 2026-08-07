import 'package:pick_my_snacks/src/data/model/take_away_processing.dart';

abstract interface class TakeAwayCompletedViewRepository {
  Future<TakeAwayProcessingResponse> getCompletedTakeAwayView(
    int completedOrderId,
    int holdOrderId,
  );
}
