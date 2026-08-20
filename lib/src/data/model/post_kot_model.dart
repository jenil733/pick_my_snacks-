import 'package:pick_my_snacks/src/data/model/save_order.dart';

class KotOrderRequest {
  const KotOrderRequest({
    required this.tableId,
    required this.staffId,
    required this.paymentMode,
    required this.products,
    this.discountType = 'none',
    this.discountValue = 0,
    this.offer = '',
    this.discountReason = '',
    this.charge = 0,
    this.chargeReason = '',
    this.customerName,
    this.customerPhone,
    this.isKot = true,
  });

  final int tableId;
  final int staffId;
  final String paymentMode;
  final List<SaveOrderProductRequest> products;
  final String discountType;
  final double discountValue;
  final String offer;
  final String discountReason;
  final double charge;
  final String chargeReason;
  final String? customerName;
  final String? customerPhone;
  final bool isKot;

  Map<String, dynamic> toFormFields() {
    final fields = <String, dynamic>{
      'table_id': tableId,
      'staff_id': staffId,
      'payment_mode': paymentMode,
      'discount_type': discountType,
      'is_kot': isKot ? 1 : 0,
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
    final normalizedCustomerName = customerName?.trim();
    if (normalizedCustomerName != null && normalizedCustomerName.isNotEmpty) {
      fields['customer_name'] = normalizedCustomerName;
    }
    final normalizedCustomerPhone = customerPhone?.trim();
    if (normalizedCustomerPhone != null && normalizedCustomerPhone.isNotEmpty) {
      fields['customer_phone'] = normalizedCustomerPhone;
    }
    for (var index = 0; index < products.length; index++) {
      final product = products[index];
      fields['products[$index][product_id]'] = product.productId;
      fields['products[$index][qty]'] = product.apiQuantity;
      fields['products[$index][note]'] = product.note.trim();
      fields['products[$index][is_kot]'] = (product.isKot ?? isKot) ? 1 : 0;
    }
    return fields;
  }
}

class KotOrderResponse {
  const KotOrderResponse({this.status, this.message, this.data});

  factory KotOrderResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return KotOrderResponse(
      status: _toBool(json['status']),
      message: json['message']?.toString(),
      data: rawData is Map
          ? KotOrderData.fromJson(Map<String, dynamic>.from(rawData))
          : null,
    );
  }

  final bool? status;
  final String? message;
  final KotOrderData? data;
}

class KotOrderData {
  const KotOrderData({this.authenticatedCounter, this.table, this.order});

  factory KotOrderData.fromJson(Map<String, dynamic> json) {
    final counter = json['authenticated_counter'];
    final table = json['table'];
    final order = json['order'];
    return KotOrderData(
      authenticatedCounter: counter is Map
          ? KotAuthenticatedCounter.fromJson(Map<String, dynamic>.from(counter))
          : null,
      table: table is Map
          ? KotTable.fromJson(Map<String, dynamic>.from(table))
          : null,
      order: order is Map
          ? KotOrder.fromJson(Map<String, dynamic>.from(order))
          : null,
    );
  }

  final KotAuthenticatedCounter? authenticatedCounter;
  final KotTable? table;
  final KotOrder? order;
}

class KotAuthenticatedCounter {
  const KotAuthenticatedCounter({
    this.counterId,
    this.counterName,
    this.branchId,
  });

  factory KotAuthenticatedCounter.fromJson(Map<String, dynamic> json) {
    return KotAuthenticatedCounter(
      counterId: _toInt(json['counter_id']),
      counterName: json['counter_name']?.toString(),
      branchId: _toInt(json['branch_id']),
    );
  }

  final int? counterId;
  final String? counterName;
  final int? branchId;
}

class KotTable {
  const KotTable({this.id, this.tableId, this.isActive});

  factory KotTable.fromJson(Map<String, dynamic> json) {
    return KotTable(
      id: _toInt(json['id']),
      tableId: _toInt(json['table_id']),
      isActive: _toBool(json['is_active']),
    );
  }

  final int? id;
  final int? tableId;
  final bool? isActive;
}

class KotOrder {
  const KotOrder({
    this.id,
    this.orderId,
    this.tableId,
    this.branchId,
    this.staffId,
    this.customerName,
    this.customerPhone,
    this.subtotal,
    this.gst,
    this.discount,
    this.charge,
    this.total,
    this.paymentMode,
    this.status,
    this.billedIn,
    this.products,
  });

  factory KotOrder.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'];
    return KotOrder(
      id: _toInt(json['id']),
      orderId: json['order_id']?.toString(),
      tableId: _toInt(json['table_id']),
      branchId: _toInt(json['branch_id']),
      staffId: _toInt(json['staff_id']),
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      subtotal: _toDouble(json['subtotal']),
      gst: _toDouble(json['gst']),
      discount: _toDouble(json['discount']),
      charge: _toDouble(json['charge']),
      total: _toDouble(json['total']),
      paymentMode: json['payment_mode']?.toString(),
      status: json['status']?.toString(),
      billedIn: json['billed_in']?.toString(),
      products: rawProducts is List
          ? rawProducts
                .whereType<Map>()
                .map(
                  (item) =>
                      KotProduct.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : <KotProduct>[],
    );
  }

  final int? id;
  final String? orderId;
  final int? tableId;
  final int? branchId;
  final int? staffId;
  final String? customerName;
  final String? customerPhone;
  final double? subtotal;
  final double? gst;
  final double? discount;
  final double? charge;
  final double? total;
  final String? paymentMode;
  final String? status;
  final String? billedIn;
  final List<KotProduct>? products;
}

class KotProduct {
  const KotProduct({
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
    this.isKot,
    this.createdAt,
    this.updatedAt,
  });

  factory KotProduct.fromJson(Map<String, dynamic> json) {
    return KotProduct(
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
      isKot: _toBool(json['is_kot']),
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
  final bool? isKot;
  final String? createdAt;
  final String? updatedAt;
}

int? _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
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
