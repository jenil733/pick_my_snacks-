import 'package:pick_my_snacks/src/data/model/save_order.dart';

class TakeAwayHoldRequest {
  const TakeAwayHoldRequest({
    required this.staffId,
    required this.paymentMode,
    required this.products,
    this.holdOrderId,
    this.userId = '',
    this.customerName = '',
    this.customerPhone = '',
    this.charge = 0,
    this.status = '',
    this.discountType = 'none',
    this.discountValue = 0,
    this.printKitchen = true,
  });

  final int staffId;
  final int? holdOrderId;
  final String userId;
  final String customerName;
  final String customerPhone;
  final double charge;
  final String paymentMode;
  final String status;
  final List<SaveOrderProductRequest> products;
  final String discountType;
  final double discountValue;
  final bool printKitchen;

  Map<String, dynamic> toFormFields() {
    final hasDiscount =
        discountType != 'none' && discountType.trim().isNotEmpty;
    final fields = <String, dynamic>{
      'staff_id': staffId,
      'user_id': userId.trim(),
      'customer_name': customerName.trim(),
      'customer_phone': customerPhone.trim(),
      'charge': charge,
      'payment_mode': paymentMode,
      'status': status.trim(),
      'discount_type': hasDiscount ? discountType : '',
      'discount_value': hasDiscount ? discountValue : '',
      'discount': hasDiscount ? discountValue : 0,
      'offer': 0,
      'print_kitchen': printKitchen ? 1 : 0,
    };
    if (holdOrderId != null) {
      fields['hold_order_id'] = holdOrderId;
    }

    for (var index = 0; index < products.length; index++) {
      final product = products[index];
      fields['products[$index][product_id]'] = product.productId;
      fields['products[$index][qty]'] = product.apiQuantity;
      fields['products[$index][note]'] = product.note.trim();
      // A take-away product is sent as pending KOT. The API marks it after
      // handling the kitchen print and records print_target/printed_at.
      fields['products[$index][is_kot]'] = 0;
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
          ? TakeAwayHoldData.fromJson(Map<String, dynamic>.from(rawData))
          : null,
    );
  }

  final bool? status;
  final String? message;
  final TakeAwayHoldData? data;
}

class TakeAwayHoldData {
  const TakeAwayHoldData({this.isProcessing, this.order});

  factory TakeAwayHoldData.fromJson(Map<String, dynamic> json) {
    final rawOrder = json['order'];
    return TakeAwayHoldData(
      isProcessing: _toBool(json['is_processing']),
      order: rawOrder is Map
          ? TakeAwayHoldOrder.fromJson(Map<String, dynamic>.from(rawOrder))
          : null,
    );
  }

  final bool? isProcessing;
  final TakeAwayHoldOrder? order;
}

class TakeAwayHoldOrder {
  const TakeAwayHoldOrder({
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
    this.products = const <TakeAwayHoldProduct>[],
  });

  factory TakeAwayHoldOrder.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'];
    return TakeAwayHoldOrder(
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
                  (product) => TakeAwayHoldProduct.fromJson(
                    Map<String, dynamic>.from(product),
                  ),
                )
                .toList()
          : const <TakeAwayHoldProduct>[],
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
  final List<TakeAwayHoldProduct> products;
}

class TakeAwayHoldProduct {
  const TakeAwayHoldProduct({
    this.id,
    this.orderId,
    this.productId,
    this.productName,
    this.productCode,
    this.variantCode,
    this.mrp,
    this.price,
    this.quantity,
    this.note,
    this.unitValue,
    this.unit,
    this.tax,
    this.rowTotal,
    this.isKot,
    this.printTarget,
    this.printedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory TakeAwayHoldProduct.fromJson(Map<String, dynamic> json) {
    return TakeAwayHoldProduct(
      id: _toInt(json['id']),
      orderId: _toInt(json['order_id']),
      productId: _toInt(json['product_id']),
      productName: json['product_name']?.toString(),
      productCode: json['product_code']?.toString(),
      variantCode: json['variant_code']?.toString(),
      mrp: _toDouble(json['mrp']),
      price: _toDouble(json['price']),
      quantity: _toInt(json['quantity']),
      note: json['note']?.toString(),
      unitValue: _toDouble(json['unit_value']),
      unit: json['unit']?.toString(),
      tax: _toDouble(json['tax']),
      rowTotal: _toDouble(json['row_total']),
      isKot: _toBool(json['is_kot']),
      printTarget: json['print_target']?.toString(),
      printedAt: json['printed_at']?.toString(),
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
  final String? note;
  final double? unitValue;
  final String? unit;
  final double? tax;
  final double? rowTotal;
  final bool? isKot;
  final String? printTarget;
  final String? printedAt;
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
