import 'package:pick_my_snacks/src/data/model/save_order.dart';

class HoldOrderRequest {
  const HoldOrderRequest({
    required this.staffId,
    required this.paymentMode,
    required this.products,
    this.discountType = 'none',
    this.discountValue = 0,
    this.offer = '',
    this.discountReason = '',
    this.charge = 0,
    this.chargeReason = '',
  });

  final int staffId;
  final String discountType;
  final double discountValue;
  final String offer;
  final String discountReason;
  final double charge;
  final String chargeReason;
  final String paymentMode;
  final List<SaveOrderProductRequest> products;

  Map<String, dynamic> toFormFields() {
    final fields = <String, dynamic>{
      'staff_id': staffId,
      'discount_type': discountType,
      'payment_mode': paymentMode,
    };

    if (discountType != 'none') {
      fields['discount_value'] = discountValue;
      if (offer.trim().isNotEmpty) fields['offer'] = offer.trim();
      if (discountReason.trim().isNotEmpty) {
        fields['discount_reason'] = discountReason.trim();
      }
    }
    if (charge > 0) {
      fields['charge'] = charge;
      if (chargeReason.trim().isNotEmpty) {
        fields['charge_reason'] = chargeReason.trim();
      }
    }

    for (var index = 0; index < products.length; index++) {
      final product = products[index];
      fields['products[$index][product_id]'] = product.productId;
      fields['products[$index][qty]'] = product.quantity;
    }
    return fields;
  }
}

class HoldOrderResponse {
  const HoldOrderResponse({this.status, this.message, this.data});

  factory HoldOrderResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return HoldOrderResponse(
      status: _toBool(json['status']),
      message: json['message']?.toString(),
      data: rawData is Map
          ? SaveOrderData.fromJson(Map<String, dynamic>.from(rawData))
          : null,
    );
  }

  final bool? status;
  final String? message;
  final SaveOrderData? data;

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'data': data?.toJson(),
  };
}

bool? _toBool(Object? value) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}
