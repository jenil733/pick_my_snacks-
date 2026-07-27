class GetHoldOrdersResponse {
  const GetHoldOrdersResponse({this.status, this.message, this.data});

  factory GetHoldOrdersResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return GetHoldOrdersResponse(
      status: _toBool(json['status']),
      message: json['message']?.toString(),
      data: rawData is List
          ? rawData
                .whereType<Map>()
                .map(
                  (item) => HeldOrderSummary.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : <HeldOrderSummary>[],
    );
  }

  final bool? status;
  final String? message;
  final List<HeldOrderSummary>? data;

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'data': data?.map((item) => item.toJson()).toList(),
  };
}

class HeldOrderSummary {
  const HeldOrderSummary({
    this.id,
    this.orderId,
    this.dateTime,
    this.itemsCount,
    this.subtotal,
    this.gst,
    this.discount,
    this.charge,
    this.total,
    this.customerName,
    this.customerPhone,
    this.paymentMode,
    this.staffId,
    this.status,
  });

  factory HeldOrderSummary.fromJson(Map<String, dynamic> json) {
    return HeldOrderSummary(
      id: _toInt(json['id']),
      orderId: json['order_id']?.toString(),
      dateTime: json['date_time']?.toString(),
      itemsCount: _toInt(json['items_count']),
      subtotal: _toDouble(json['subtotal']),
      gst: _toDouble(json['gst']),
      discount: _toDouble(json['discount']),
      charge: _toDouble(json['charge']),
      total: _toDouble(json['total']),
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      paymentMode: json['payment_mode']?.toString(),
      staffId: json['staff_id']?.toString(),
      status: json['status']?.toString(),
    );
  }

  final int? id;
  final String? orderId;
  final String? dateTime;
  final int? itemsCount;
  final double? subtotal;
  final double? gst;
  final double? discount;
  final double? charge;
  final double? total;
  final Object? customerName;
  final Object? customerPhone;
  final String? paymentMode;
  final String? staffId;
  final String? status;

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'date_time': dateTime,
    'items_count': itemsCount,
    'subtotal': subtotal,
    'gst': gst,
    'discount': discount,
    'charge': charge,
    'total': total,
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'payment_mode': paymentMode,
    'staff_id': staffId,
    'status': status,
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

bool? _toBool(Object? value) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}
