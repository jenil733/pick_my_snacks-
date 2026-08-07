import 'package:pick_my_snacks/src/data/model/take_away_processing.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_processing_repository.dart';

class GetTakeAwayProcessingUseCase {
  const GetTakeAwayProcessingUseCase(this._repository);

  final TakeAwayProcessingRepository _repository;

  Future<TakeAwayProcessingResponse> call([int? holdOrderId]) {
    return _repository.getProcessingTakeAway(holdOrderId);
  }
}
