class ProcessingOrderResponse {
  const ProcessingOrderResponse({this.status, this.message, this.data});

  factory ProcessingOrderResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return ProcessingOrderResponse(
      status: _toBool(json['status']),
      message: json['message']?.toString(),
      data: rawData is Map
          ? ProcessingOrderData.fromJson(Map<String, dynamic>.from(rawData))
          : null,
    );
  }

  final bool? status;
  final String? message;
  final ProcessingOrderData? data;
}

class ProcessingOrderData {
  const ProcessingOrderData({this.isProcessing, this.table, this.order});

  factory ProcessingOrderData.fromJson(Map<String, dynamic> json) {
    final rawTable = json['table'];
    final rawOrder = json['order'];
    return ProcessingOrderData(
      isProcessing: _toBool(json['is_processing']),
      table: rawTable is Map
          ? ProcessingTable.fromJson(Map<String, dynamic>.from(rawTable))
          : null,
      order: rawOrder is Map
          ? ProcessingOrder.fromJson(Map<String, dynamic>.from(rawOrder))
          : null,
    );
  }

  final bool? isProcessing;
  final ProcessingTable? table;
  final ProcessingOrder? order;
}

class ProcessingTable {
  const ProcessingTable({this.id, this.tableId, this.branchId, this.isActive});

  factory ProcessingTable.fromJson(Map<String, dynamic> json) {
    return ProcessingTable(
      id: _toInt(json['id']),
      tableId: _toInt(json['table_id']),
      branchId: _toInt(json['branch_id']),
      isActive: _toBool(json['is_active']),
    );
  }

  final int? id;
  final int? tableId;
  final int? branchId;
  final bool? isActive;
}

class ProcessingOrder {
  const ProcessingOrder({
    this.id,
    this.orderId,
    this.processingOrderCount,
    this.processingOrderIds = const <int>[],
    this.processingOrderNumbers = const <String>[],
    this.tableId,
    this.branchId,
    this.staffId,
    this.staffName,
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
    this.createdAt,
    this.products,
  });

  factory ProcessingOrder.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'];
    return ProcessingOrder(
      id: _toInt(json['id']),
      orderId: json['order_id']?.toString(),
      processingOrderCount: _toInt(json['processing_order_count']),
      processingOrderIds: _toIntList(json['processing_order_ids']),
      processingOrderNumbers: _toStringList(json['processing_order_numbers']),
      tableId: _toInt(json['table_id']),
      branchId: _toInt(json['branch_id']),
      staffId: _toInt(json['staff_id']),
      staffName: json['staff_name']?.toString(),
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
      createdAt: json['created_at']?.toString(),
      products: rawProducts is List
          ? rawProducts
                .whereType<Map>()
                .map(
                  (item) => ProcessingProduct.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : <ProcessingProduct>[],
    );
  }

  final int? id;
  final String? orderId;
  final int? processingOrderCount;
  final List<int> processingOrderIds;
  final List<String> processingOrderNumbers;
  final int? tableId;
  final int? branchId;
  final int? staffId;
  final String? staffName;
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
  final String? createdAt;
  final List<ProcessingProduct>? products;
}

class ProcessingProduct {
  const ProcessingProduct({
    this.id,
    this.holdOrderId,
    this.holdOrderNumber,
    this.productId,
    this.productCode,
    this.productName,
    this.variantCode,
    this.mrp,
    this.price,
    this.quantity,
    this.unitValue,
    this.unit,
    this.tax,
    this.rowTotal,
    this.isKot,
  });

  factory ProcessingProduct.fromJson(Map<String, dynamic> json) {
    return ProcessingProduct(
      id: _toInt(json['id']),
      holdOrderId: _toInt(json['hold_order_id']),
      holdOrderNumber: json['hold_order_number']?.toString(),
      productId: _toInt(json['product_id']),
      productCode: json['product_code']?.toString(),
      productName: json['product_name']?.toString(),
      variantCode: json['variant_code']?.toString(),
      mrp: _toDouble(json['mrp']),
      price: _toDouble(json['price']),
      quantity: _toInt(json['quantity']),
      unitValue: _toDouble(json['unit_value']),
      unit: json['unit']?.toString(),
      tax: _toDouble(json['tax']),
      rowTotal: _toDouble(json['row_total']),
      isKot: _toBool(json['is_kot']),
    );
  }

  final int? id;
  final int? holdOrderId;
  final String? holdOrderNumber;
  final int? productId;
  final String? productCode;
  final String? productName;
  final String? variantCode;
  final double? mrp;
  final double? price;
  final int? quantity;
  final double? unitValue;
  final String? unit;
  final double? tax;
  final double? rowTotal;
  final bool? isKot;
}

int? _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

List<int> _toIntList(Object? value) {
  if (value is! List) return const <int>[];
  return value.map(_toInt).whereType<int>().toList();
}

List<String> _toStringList(Object? value) {
  if (value is! List) return const <String>[];
  return value
      .map((item) => item?.toString())
      .whereType<String>()
      .where((item) => item.isNotEmpty)
      .toList();
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
