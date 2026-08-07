import 'package:pick_my_snacks/src/data/model/processing.dart';

abstract interface class ProcessingOrderRepository {
  Future<ProcessingOrderResponse> getProcessingOrder(int tableId);
}
