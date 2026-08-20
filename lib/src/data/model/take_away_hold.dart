import 'package:pick_my_snacks/src/data/model/save_order.dart';

class TakeAwayHoldRequest {
  const TakeAwayHoldRequest({
    required this.staffId,
    required this.paymentMode,
    required this.products,
    this.userId = '',
    this.customerName = '',
    this.customerPhone = '',
    this.charge = 0,
    this.status = '',
    this.discountType = 'none',
    this.discountValue = 0,
  });

  final int staffId;
  final String userId;
  final String customerName;
  final String customerPhone;
  final double charge;
  final String paymentMode;
  final String status;
  final List<SaveOrderProductRequest> products;
  final String discountType;
  final double discountValue;

  Map<String, dynamic> toFormFields() {
    final hasDiscount =
        discountType != 'none' && discountType.trim().isNotEmpty;
    final fields = <String, dynamic>{
      'staff_id': staffId,
      'user_id': userId.trim(),
      'customer_name': customerName.trim(),
      'customer_phone': customerPhone.trim(),
      'charge': charge > 0 ? charge : '',
      'payment_mode': paymentMode,
      'status': status.trim(),
      'discount_type': hasDiscount ? discountType : '',
      'discount_value': hasDiscount ? discountValue : '',
      'is_kot': 1,
    };

    for (var index = 0; index < products.length; index++) {
      final product = products[index];
      fields['products[$index][product_id]'] = product.productId;
      fields['products[$index][qty]'] = product.apiQuantity;
      fields['products[$index][note]'] = product.note.trim();
    }
    return fields;
  }
}

class TakeAwayHoldResponse {
  const TakeAwayHoldResponse({this.status, this.message, this.data});

  factory TakeAwayHoldResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return TakeAwayHoldResponse(
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
}

bool? _toBool(Object? value) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}
