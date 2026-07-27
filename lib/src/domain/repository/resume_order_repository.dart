import 'package:pick_my_snacks/src/data/model/get_resume.dart';

abstract interface class ResumeOrderRepository {
  Future<ResumeOrderResponse> resumeOrder(int orderId);
}
