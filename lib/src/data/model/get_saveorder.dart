class KotSaveResponse {
  const KotSaveResponse({this.status, this.message, this.data});

  factory KotSaveResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return KotSaveResponse(
      status: _toBool(json['status']),
      message: json['message']?.toString(),
      data: rawData is Map
          ? KotSaveData.fromJson(Map<String, dynamic>.from(rawData))
          : null,
    );
  }

  final bool? status;
  final String? message;
  final KotSaveData? data;
}

class KotSaveData {
  const KotSaveData({
    this.isProcessing,
    this.table,
    this.completedHoldOrderIds = const [],
    this.completedHoldOrderCount,
    this.completedOrder,
  });

  factory KotSaveData.fromJson(Map<String, dynamic> json) {
    final rawTable = json['table'];
    final rawIds = json['completed_hold_order_ids'];
    final rawOrder = json['completed_order'];
    return KotSaveData(
      isProcessing: _toBool(json['is_processing']),
      table: rawTable is Map
          ? KotSaveTable.fromJson(Map<String, dynamic>.from(rawTable))
          : null,
      completedHoldOrderIds: rawIds is List
          ? rawIds.map(_toInt).whereType<int>().toList()
          : const [],
      completedHoldOrderCount: _toInt(json['completed_hold_order_count']),
      completedOrder: rawOrder is Map
          ? KotCompletedOrder.fromJson(Map<String, dynamic>.from(rawOrder))
          : null,
    );
  }

  final bool? isProcessing;
  final KotSaveTable? table;
  final List<int> completedHoldOrderIds;
  final int? completedHoldOrderCount;
  final KotCompletedOrder? completedOrder;
}

class KotSaveTable {
  const KotSaveTable({this.id, this.tableId, this.branchId});

  factory KotSaveTable.fromJson(Map<String, dynamic> json) {
    return KotSaveTable(
      id: _toInt(json['id']),
      tableId: _toInt(json['table_id']),
      branchId: _toInt(json['branch_id']),
    );
  }

  final int? id;
  final int? tableId;
  final int? branchId;
}

class KotCompletedOrder {
  const KotCompletedOrder({
    this.id,
    this.orderId,
    this.tableId,
    this.branchId,
    this.subtotal,
    this.gst,
    this.discount,
    this.charge,
    this.total,
    this.paymentMode,
    this.status,
    this.products = const [],
  });

  factory KotCompletedOrder.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'];
    return KotCompletedOrder(
      id: _toInt(json['id']),
      orderId: json['order_id']?.toString(),
      tableId: _toInt(json['table_id']),
      branchId: _toInt(json['branch_id']),
      subtotal: _toDouble(json['subtotal']),
      gst: _toDouble(json['gst']),
      discount: _toDouble(json['discount']),
      charge: _toDouble(json['charge']),
      total: _toDouble(json['total']),
      paymentMode: json['payment_mode']?.toString(),
      status: json['status']?.toString(),
      products: rawProducts is List
          ? rawProducts
                .whereType<Map>()
                .map(
                  (item) =>
                      KotSavedProduct.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }

  final int? id;
  final String? orderId;
  final int? tableId;
  final int? branchId;
  final double? subtotal;
  final double? gst;
  final double? discount;
  final double? charge;
  final double? total;
  final String? paymentMode;
  final String? status;
  final List<KotSavedProduct> products;
}

class KotSavedProduct {
  const KotSavedProduct({
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

  factory KotSavedProduct.fromJson(Map<String, dynamic> json) {
    return KotSavedProduct(
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
  final text = value?.toString().trim() ?? '';
  final direct = int.tryParse(text);
  if (direct != null) return direct;
  final numericPrefix = RegExp(r'^\d+').firstMatch(text)?.group(0);
  return int.tryParse(numericPrefix ?? '');
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
