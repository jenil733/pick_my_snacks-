import 'package:pick_my_snacks/src/data/model/remove_kot_quantity.dart';

class TakeAwayChangeQuantityRequest {
  const TakeAwayChangeQuantityRequest({
    required this.orderId,
    required this.detailId,
    required this.removeQuantity,
  });

  final int orderId;
  final int detailId;
  final num removeQuantity;

  Map<String, dynamic> toFormFields() => <String, dynamic>{
    'order_id': orderId,
    'detail_id': detailId,
    'remove_quantity': removeQuantity,
  };
}

typedef TakeAwayChangeQuantityResponse = RemoveKotQuantityResponse;
