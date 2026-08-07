class RemoveKotQuantityRequest {
  const RemoveKotQuantityRequest({
    required this.orderId,
    required this.detailId,
    required this.removeQuantity,
  });

  final int orderId;
  final num removeQuantity;
  final int detailId;

  Map<String, dynamic> toFormFields() => <String, dynamic>{
    'order_id': orderId,
    'detail_id': detailId,
    'remove_quantity': removeQuantity,
  };
}

class RemoveKotQuantityResponse {
  const RemoveKotQuantityResponse({this.status, this.message, this.data});

  factory RemoveKotQuantityResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return RemoveKotQuantityResponse(
      status: _toBool(json['status']),
      message: json['message']?.toString(),
      data: rawData is Map
          ? RemoveKotQuantityData.fromJson(Map<String, dynamic>.from(rawData))
          : null,
    );
  }

  final bool? status;
  final String? message;
  final RemoveKotQuantityData? data;
}

class RemoveKotQuantityData {
  const RemoveKotQuantityData({this.product, this.order});

  factory RemoveKotQuantityData.fromJson(Map<String, dynamic> json) {
    final rawProduct = json['product'];
    final rawOrder = json['order'];
    return RemoveKotQuantityData(
      product: rawProduct is Map
          ? RemovedKotQuantityProduct.fromJson(
              Map<String, dynamic>.from(rawProduct),
            )
          : null,
      order: rawOrder is Map
          ? RemoveKotQuantityOrder.fromJson(Map<String, dynamic>.from(rawOrder))
          : null,
    );
  }

  final RemovedKotQuantityProduct? product;
  final RemoveKotQuantityOrder? order;
}

class RemovedKotQuantityProduct {
  const RemovedKotQuantityProduct({
    this.detailId,
    this.productId,
    this.productName,
    this.previousQuantity,
    this.removedQuantity,
    this.remainingQuantity,
    this.remainingUnitValue,
    this.rowTotal,
  });

  factory RemovedKotQuantityProduct.fromJson(Map<String, dynamic> json) {
    return RemovedKotQuantityProduct(
      detailId: _toInt(json['detail_id']),
      productId: _toInt(json['product_id']),
      productName: json['product_name']?.toString(),
      previousQuantity: _toDouble(json['previous_quantity']),
      removedQuantity: _toDouble(json['removed_quantity']),
      remainingQuantity: _toDouble(json['remaining_quantity']),
      remainingUnitValue: _toDouble(json['remaining_unit_value']),
      rowTotal: _toDouble(json['row_total']),
    );
  }

  final int? detailId;
  final int? productId;
  final String? productName;
  final double? previousQuantity;
  final double? removedQuantity;
  final double? remainingQuantity;
  final double? remainingUnitValue;
  final double? rowTotal;
}

class RemoveKotQuantityOrder {
  const RemoveKotQuantityOrder({
    this.id,
    this.orderId,
    this.tableId,
    this.branchId,
    this.staffId,
    this.subtotal,
    this.gst,
    this.discount,
    this.charge,
    this.total,
    this.status,
    this.products = const <RemoveKotQuantityOrderProduct>[],
  });

  factory RemoveKotQuantityOrder.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'];
    return RemoveKotQuantityOrder(
      id: _toInt(json['id']),
      orderId: json['order_id']?.toString(),
      tableId: _toInt(json['table_id']),
      branchId: _toInt(json['branch_id']),
      staffId: _toInt(json['staff_id']),
      subtotal: _toDouble(json['subtotal']),
      gst: _toDouble(json['gst']),
      discount: _toDouble(json['discount']),
      charge: _toDouble(json['charge']),
      total: _toDouble(json['total']),
      status: json['status']?.toString(),
      products: rawProducts is List
          ? rawProducts
                .whereType<Map>()
                .map(
                  (item) => RemoveKotQuantityOrderProduct.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const <RemoveKotQuantityOrderProduct>[],
    );
  }

  final int? id;
  final String? orderId;
  final int? tableId;
  final int? branchId;
  final int? staffId;
  final double? subtotal;
  final double? gst;
  final double? discount;
  final double? charge;
  final double? total;
  final String? status;
  final List<RemoveKotQuantityOrderProduct> products;
}

class RemoveKotQuantityOrderProduct {
  const RemoveKotQuantityOrderProduct({
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

  factory RemoveKotQuantityOrderProduct.fromJson(Map<String, dynamic> json) {
    return RemoveKotQuantityOrderProduct(
      id: _toInt(json['id']),
      orderId: _toInt(json['order_id']),
      productId: _toInt(json['product_id']),
      productName: json['product_name']?.toString(),
      productCode: json['product_code']?.toString(),
      variantCode: json['variant_code']?.toString(),
      mrp: _toDouble(json['mrp']),
      price: _toDouble(json['price']),
      quantity: json['quantity']?.toString(),
      unitValue: json['unit_value']?.toString(),
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
  final String? quantity;
  final String? unitValue;
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
