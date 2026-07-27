class GetProductResponse {
  const GetProductResponse({this.success, this.message, this.data});

  factory GetProductResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return GetProductResponse(
      success: _toBool(json['success']),
      message: json['message']?.toString(),
      data: rawData is List
          ? rawData
                .whereType<Map>()
                .map((item) => Data.fromJson(Map<String, dynamic>.from(item)))
                .toList()
          : <Data>[],
    );
  }

  final bool? success;
  final String? message;
  final List<Data>? data;

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data?.map((item) => item.toJson()).toList(),
  };
}

class Data {
  const Data({
    this.id,
    this.productName,
    this.productId,
    this.image,
    this.price,
    this.mrp,
    this.tax,
    this.stock,
    this.unitValue,
    this.unit,
    this.isActive,
    this.packedDate,
    this.expiryDate,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      id: _toInt(json['id']),
      productName: json['product_name']?.toString(),
      productId: json['product_id']?.toString(),
      image: json['image']?.toString(),
      price: _toNum(json['price']),
      mrp: _toNum(json['mrp']),
      tax: _toNum(json['tax']),
      stock: _toNum(json['stock']),
      unitValue: _toNum(json['unit_value']),
      unit: json['unit']?.toString(),
      isActive: _toBool(json['is_active']),
      packedDate: json['packed_date'],
      expiryDate: json['expiry_date'],
    );
  }

  final int? id;
  final String? productName;
  final String? productId;
  final String? image;
  final num? price;
  final num? mrp;
  final num? tax;
  final num? stock;
  final num? unitValue;
  final String? unit;
  final bool? isActive;
  final Object? packedDate;
  final Object? expiryDate;

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_name': productName,
    'product_id': productId,
    'image': image,
    'price': price,
    'mrp': mrp,
    'tax': tax,
    'stock': stock,
    'unit_value': unitValue,
    'unit': unit,
    'is_active': isActive,
    'packed_date': packedDate,
    'expiry_date': expiryDate,
  };
}

num? _toNum(Object? value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '');
}

int? _toInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

bool? _toBool(Object? value) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}
