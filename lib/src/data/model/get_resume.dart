class ResumeOrderResponse {
  const ResumeOrderResponse({this.status, this.message, this.data});

  factory ResumeOrderResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return ResumeOrderResponse(
      status: _toBool(json['status']),
      message: json['message']?.toString(),
      data: rawData is Map
          ? ResumeOrderData.fromJson(Map<String, dynamic>.from(rawData))
          : null,
    );
  }

  final bool? status;
  final String? message;
  final ResumeOrderData? data;
}

class ResumeOrderData {
  const ResumeOrderData({this.bill, this.products});

  factory ResumeOrderData.fromJson(Map<String, dynamic> json) {
    final rawBill = json['bill'];
    final rawProducts = json['products'];
    return ResumeOrderData(
      bill: rawBill is Map
          ? ResumedBill.fromJson(Map<String, dynamic>.from(rawBill))
          : null,
      products: rawProducts is List
          ? rawProducts
                .whereType<Map>()
                .map(
                  (item) =>
                      ResumedProduct.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : <ResumedProduct>[],
    );
  }

  final ResumedBill? bill;
  final List<ResumedProduct>? products;
}

class ResumedBill {
  const ResumedBill({
    this.id,
    this.orderId,
    this.userId,
    this.staffId,
    this.customerName,
    this.customerPhone,
    this.subtotal,
    this.gst,
    this.discountType,
    this.discountValue,
    this.discount,
    this.offer,
    this.discountReason,
    this.charge,
    this.total,
    this.paymentMode,
    this.status,
  });

  factory ResumedBill.fromJson(Map<String, dynamic> json) {
    return ResumedBill(
      id: _toInt(json['id']),
      orderId: json['order_id']?.toString(),
      userId: json['user_id'],
      staffId: json['staff_id']?.toString(),
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      subtotal: _toDouble(json['subtotal']),
      gst: _toDouble(json['gst']),
      discountType: json['discount_type']?.toString(),
      discountValue: _toDouble(json['discount_value']),
      discount: _toDouble(json['discount']),
      offer: json['offer'],
      discountReason: json['discount_reason']?.toString(),
      charge: _toDouble(json['charge']),
      total: _toDouble(json['total']),
      paymentMode: json['payment_mode']?.toString(),
      status: json['status']?.toString(),
    );
  }

  final int? id;
  final String? orderId;
  final Object? userId;
  final String? staffId;
  final Object? customerName;
  final Object? customerPhone;
  final double? subtotal;
  final double? gst;
  final String? discountType;
  final double? discountValue;
  final double? discount;
  final Object? offer;
  final String? discountReason;
  final double? charge;
  final double? total;
  final String? paymentMode;
  final String? status;
}

class ResumedProduct {
  const ResumedProduct({
    this.id,
    this.productId,
    this.productName,
    this.name,
    this.productCode,
    this.code,
    this.variantCode,
    this.mrp,
    this.price,
    this.qty,
    this.quantity,
    this.unitValue,
    this.unit,
    this.tax,
    this.rowTotal,
  });

  factory ResumedProduct.fromJson(Map<String, dynamic> json) {
    return ResumedProduct(
      id: _toInt(json['id']),
      productId: _toInt(json['product_id']),
      productName: json['product_name']?.toString(),
      name: json['name']?.toString(),
      productCode: json['product_code']?.toString(),
      code: json['code']?.toString(),
      variantCode: json['variant_code']?.toString(),
      mrp: _toDouble(json['mrp']),
      price: _toDouble(json['price']),
      qty: _toInt(json['qty']),
      quantity: _toInt(json['quantity']),
      unitValue: _toDouble(json['unit_value']),
      unit: json['unit']?.toString(),
      tax: _toDouble(json['tax']),
      rowTotal: _toDouble(json['row_total']),
    );
  }

  final int? id;
  final int? productId;
  final String? productName;
  final String? name;
  final String? productCode;
  final String? code;
  final String? variantCode;
  final double? mrp;
  final double? price;
  final int? qty;
  final int? quantity;
  final double? unitValue;
  final String? unit;
  final double? tax;
  final double? rowTotal;
}

int? _toInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

double? _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

bool? _toBool(Object? value) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}
