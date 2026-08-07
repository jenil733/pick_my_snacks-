import 'package:pick_my_snacks/src/data/model/save_order.dart';

class TakeAwaySaveOrderRequest {
  const TakeAwaySaveOrderRequest({required this.holdOrderId});

  final int holdOrderId;

  Map<String, dynamic> toFormFields() => <String, dynamic>{
    'hold_order_id': holdOrderId,
  };
}

class TakeAwaySaveOrderResponse {
  const TakeAwaySaveOrderResponse({this.status, this.message, this.order});

  factory TakeAwaySaveOrderResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    Map<String, dynamic>? orderJson;
    if (rawData is Map) {
      final data = Map<String, dynamic>.from(rawData);
      final rawOrder = data['order'] ?? data['completed_order'];
      orderJson = rawOrder is Map
          ? Map<String, dynamic>.from(rawOrder)
          : data.containsKey('order_id')
          ? data
          : null;
    }
    return TakeAwaySaveOrderResponse(
      status: _toBool(json['status']),
      message: json['message']?.toString(),
      order: orderJson == null ? null : SavedOrder.fromJson(orderJson),
    );
  }

  final bool? status;
  final String? message;
  final SavedOrder? order;
}

bool? _toBool(Object? value) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}
