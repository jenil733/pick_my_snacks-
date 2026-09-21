class KotAddPersonRequest {
  const KotAddPersonRequest({
    required this.tableId,
    required this.staffId,
    required this.paymentMode,
    // The add-person API requires products[]=1 when opening an empty person.
    this.productIds = const <int>[1],
  });

  final int tableId;
  final int staffId;
  final String paymentMode;
  final List<int> productIds;

  Map<String, dynamic> toFormFields() => <String, dynamic>{
    'staff_id': staffId,
    'payment_mode': paymentMode,
    'table_id': tableId,
  };
}

class KotAddPersonResponse {
  const KotAddPersonResponse({this.status, this.message, this.personId});

  factory KotAddPersonResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return KotAddPersonResponse(
      status: _toBool(json['status']),
      message: json['message']?.toString(),
      personId: _findPersonId(data) ?? _findPersonId(json),
    );
  }

  final bool? status;
  final String? message;
  final String? personId;
}

String? _findPersonId(Object? value) {
  if (value is! Map) return _toNonEmptyString(value);
  for (final key in const <String>[
    'person_id',
    'hold_order_id',
    'id',
    'order_id',
  ]) {
    final parsed = _toNonEmptyString(value[key]);
    if (parsed != null) return parsed;
  }
  for (final key in const <String>['person', 'order', 'hold_order']) {
    final parsed = _findPersonId(value[key]);
    if (parsed != null) return parsed;
  }
  return null;
}

String? _toNonEmptyString(Object? value) {
  final normalized = value?.toString().trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

bool? _toBool(Object? value) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}
