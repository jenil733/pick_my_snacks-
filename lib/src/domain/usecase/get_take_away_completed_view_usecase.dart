import 'package:pick_my_snacks/src/data/model/take_away_processing.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_completed_view_repository.dart';

class GetTakeAwayCompletedViewUseCase {
  const GetTakeAwayCompletedViewUseCase(this._repository);

  final TakeAwayCompletedViewRepository _repository;

  Future<TakeAwayProcessingResponse> call(
    int completedOrderId,
    int holdOrderId,
  ) {
    return _repository.getCompletedTakeAwayView(completedOrderId, holdOrderId);
  }
}
