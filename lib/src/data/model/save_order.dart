class SaveOrderRequest {
  const SaveOrderRequest({
    required this.staffId,
    required this.paymentMode,
    required this.products,
    this.discountType = 'none',
  });

  final int staffId;
  final String discountType;
  final String paymentMode;
  final List<SaveOrderProductRequest> products;

  Map<String, dynamic> toFormFields() {
    final fields = <String, dynamic>{
      'staff_id': staffId,
      'discount_type': discountType,
      'payment_mode': paymentMode,
    };

    for (var index = 0; index < products.length; index++) {
      final product = products[index];
      fields['products[$index][product_id]'] = product.productId;
      fields['products[$index][qty]'] = product.quantity;
    }
    return fields;
  }
}

class SaveOrderProductRequest {
  const SaveOrderProductRequest({
    required this.productId,
    required this.quantity,
  });

  final int productId;
  final int quantity;

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'quantity': quantity,
  };
}

class SaveOrderResponse {
  const SaveOrderResponse({this.status, this.message, this.data});

  factory SaveOrderResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return SaveOrderResponse(
      status: json['status'] as bool?,
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

class SaveOrderData {
  const SaveOrderData({this.authenticatedCounter, this.order});

  factory SaveOrderData.fromJson(Map<String, dynamic> json) {
    final counter = json['authenticated_counter'];
    final order = json['order'];
    return SaveOrderData(
      authenticatedCounter: counter is Map
          ? AuthenticatedCounter.fromJson(Map<String, dynamic>.from(counter))
          : null,
      order: order is Map
          ? SavedOrder.fromJson(Map<String, dynamic>.from(order))
          : null,
    );
  }

  final AuthenticatedCounter? authenticatedCounter;
  final SavedOrder? order;

  Map<String, dynamic> toJson() => {
    'authenticated_counter': authenticatedCounter?.toJson(),
    'order': order?.toJson(),
  };
}

class AuthenticatedCounter {
  const AuthenticatedCounter({this.counterId, this.counterName, this.branchId});

  factory AuthenticatedCounter.fromJson(Map<String, dynamic> json) {
    return AuthenticatedCounter(
      counterId: _toInt(json['counter_id']),
      counterName: json['counter_name']?.toString(),
      branchId: _toInt(json['branch_id']),
    );
  }

  final int? counterId;
  final String? counterName;
  final int? branchId;

  Map<String, dynamic> toJson() => {
    'counter_id': counterId,
    'counter_name': counterName,
    'branch_id': branchId,
  };
}

class SavedOrder {
  const SavedOrder({
    this.id,
    this.orderId,
    this.branchId,
    this.staffId,
    this.subtotal,
    this.gst,
    this.discountType,
    this.discountValue,
    this.discountAmount,
    this.charge,
    this.total,
    this.paymentMode,
    this.status,
    this.products,
  });

  factory SavedOrder.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'];
    return SavedOrder(
      id: _toInt(json['id']),
      orderId: json['order_id']?.toString(),
      branchId: _toInt(json['branch_id']),
      staffId: json['staff_id']?.toString(),
      subtotal: _toDouble(json['subtotal']),
      gst: _toDouble(json['gst']),
      discountType: json['discount_type']?.toString(),
      discountValue: _toDouble(json['discount_value']),
      discountAmount: _toDouble(json['discount_amount']),
      charge: _toDouble(json['charge']),
      total: _toDouble(json['total']),
      paymentMode: json['payment_mode']?.toString(),
      status: json['status']?.toString(),
      products: rawProducts is List
          ? rawProducts
                .whereType<Map>()
                .map(
                  (item) => SavedOrderProduct.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : <SavedOrderProduct>[],
    );
  }

  final int? id;
  final String? orderId;
  final int? branchId;
  final String? staffId;
  final double? subtotal;
  final double? gst;
  final String? discountType;
  final double? discountValue;
  final double? discountAmount;
  final double? charge;
  final double? total;
  final String? paymentMode;
  final String? status;
  final List<SavedOrderProduct>? products;

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'branch_id': branchId,
    'staff_id': staffId,
    'subtotal': subtotal,
    'gst': gst,
    'discount_type': discountType,
    'discount_value': discountValue,
    'discount_amount': discountAmount,
    'charge': charge,
    'total': total,
    'payment_mode': paymentMode,
    'status': status,
    'products': products?.map((item) => item.toJson()).toList(),
  };
}

class SavedOrderProduct {
  const SavedOrderProduct({
    this.id,
    this.orderId,
    this.productId,
    this.productName,
    this.productCode,
    this.variantCode,
    this.mrp,
    this.price,
    this.quantity,
    this.unitValue,
    this.unit,
    this.tax,
    this.rowTotal,
    this.createdAt,
    this.updatedAt,
  });

  factory SavedOrderProduct.fromJson(Map<String, dynamic> json) {
    return SavedOrderProduct(
      id: _toInt(json['id']),
      orderId: _toInt(json['order_id']),
      productId: _toInt(json['product_id']),
      productName: json['product_name']?.toString(),
      productCode: json['product_code']?.toString(),
      variantCode: json['variant_code']?.toString(),
      mrp: _toDouble(json['mrp']),
      price: _toDouble(json['price']),
      quantity: _toInt(json['quantity']),
      unitValue: _toDouble(json['unit_value']),
      unit: json['unit']?.toString(),
      tax: _toDouble(json['tax']),
      rowTotal: _toDouble(json['row_total']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  final int? id;
  final int? orderId;
  final int? productId;
  final String? productName;
  final String? productCode;
  final String? variantCode;
  final double? mrp;
  final double? price;
  final int? quantity;
  final double? unitValue;
  final String? unit;
  final double? tax;
  final double? rowTotal;
  final String? createdAt;
  final String? updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'product_id': productId,
    'product_name': productName,
    'product_code': productCode,
    'variant_code': variantCode,
    'mrp': mrp,
    'price': price,
    'quantity': quantity,
    'unit_value': unitValue,
    'unit': unit,
    'tax': tax,
    'row_total': rowTotal,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

int? _toInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

double? _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
