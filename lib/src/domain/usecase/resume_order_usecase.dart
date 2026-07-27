import 'package:pick_my_snacks/src/data/model/get_resume.dart';
import 'package:pick_my_snacks/src/domain/repository/resume_order_repository.dart';

class ResumeOrderUseCase {
  const ResumeOrderUseCase(this._repository);

  final ResumeOrderRepository _repository;

  Future<ResumeOrderResponse> call(int orderId) {
    return _repository.resumeOrder(orderId);
  }
}
