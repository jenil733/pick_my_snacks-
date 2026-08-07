class TakeAwayProcessingResponse {
  const TakeAwayProcessingResponse({
    this.status,
    this.message,
    this.orders = const <TakeAwayProcessingOrder>[],
  });

  factory TakeAwayProcessingResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final orders = <TakeAwayProcessingOrder>[];
    if (rawData is List) {
      orders.addAll(_parseOrders(rawData));
    } else if (rawData is Map) {
      final data = Map<String, dynamic>.from(rawData);
      final rawOrders =
          data['orders'] ?? data['processing_orders'] ?? data['items'];
      if (rawOrders is List) {
        orders.addAll(_parseOrders(rawOrders));
      } else {
        final rawOrder = data['order'] ?? data['hold_order'] ?? data;
        if (rawOrder is Map && rawOrder.isNotEmpty) {
          orders.add(
            TakeAwayProcessingOrder.fromJson(
              Map<String, dynamic>.from(rawOrder),
            ),
          );
        }
      }
    }
    return TakeAwayProcessingResponse(
      status: _toBool(json['status']),
      message: json['message']?.toString(),
      orders: orders,
    );
  }

  final bool? status;
  final String? message;
  final List<TakeAwayProcessingOrder> orders;
}

class TakeAwayProcessingOrder {
  const TakeAwayProcessingOrder({
    this.id,
    this.holdOrderId,
    this.orderId,
    this.customerName,
    this.customerPhone,
    this.staffName,
    this.status,
    this.total,
    this.products = const <TakeAwayProcessingProduct>[],
  });

  factory TakeAwayProcessingOrder.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'] ?? json['items'];
    return TakeAwayProcessingOrder(
      id: _toInt(json['id'] ?? json['hold_order_id']),
      holdOrderId: _toInt(json['hold_order_id'] ?? json['id']),
      orderId: json['order_id']?.toString(),
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      staffName: json['staff_name']?.toString(),
      status: json['status']?.toString(),
      total: _toDouble(json['total']),
      products: rawProducts is List
          ? rawProducts
                .whereType<Map>()
                .map(
                  (item) => TakeAwayProcessingProduct.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const <TakeAwayProcessingProduct>[],
    );
  }

  final int? id;
  final int? holdOrderId;
  final String? orderId;
  final String? customerName;
  final String? customerPhone;
  final String? staffName;
  final String? status;
  final double? total;
  final List<TakeAwayProcessingProduct> products;
}

class TakeAwayProcessingProduct {
  const TakeAwayProcessingProduct({
    this.productId,
    this.productName,
    this.quantity,
    this.unit,
    this.price,
    this.rowTotal,
  });

  factory TakeAwayProcessingProduct.fromJson(Map<String, dynamic> json) {
    return TakeAwayProcessingProduct(
      productId: _toInt(json['product_id']),
      productName: (json['product_name'] ?? json['name'])?.toString(),
      quantity: (json['quantity'] ?? json['qty'])?.toString(),
      unit: json['unit']?.toString(),
      price: _toDouble(json['price']),
      rowTotal: _toDouble(json['row_total']),
    );
  }

  final int? productId;
  final String? productName;
  final String? quantity;
  final String? unit;
  final double? price;
  final double? rowTotal;
}

List<TakeAwayProcessingOrder> _parseOrders(List<dynamic> values) => values
    .whereType<Map>()
    .map(
      (item) =>
          TakeAwayProcessingOrder.fromJson(Map<String, dynamic>.from(item)),
    )
    .toList();

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
