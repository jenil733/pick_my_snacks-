import 'package:pick_my_snacks/src/data/model/processing.dart';

class KotGetPersonsResponse {
  const KotGetPersonsResponse({
    this.status,
    this.message,
    this.persons = const <KotPersonData>[],
  });

  factory KotGetPersonsResponse.fromJson(Map<String, dynamic> json) {
    return KotGetPersonsResponse(
      status: _toBool(json['status']),
      message: json['message']?.toString(),
      persons: _personList(json)
          .asMap()
          .entries
          .map(
            (entry) => KotPersonData.fromJson(
              entry.value,
              fallbackNumber: entry.key + 1,
            ),
          )
          .where((person) => person.personId.isNotEmpty)
          .toList(growable: false),
    );
  }

  final bool? status;
  final String? message;
  final List<KotPersonData> persons;
}

class KotPersonData {
  const KotPersonData({
    required this.personId,
    required this.personNumber,
    this.holdOrderIds = const <int>[],
    this.products = const <ProcessingProduct>[],
  });

  factory KotPersonData.fromJson(
    Map<String, dynamic> json, {
    required int fallbackNumber,
  }) {
    final personId = _firstNonEmpty(json, const <String>[
      'person_id',
      'personId',
      'id',
    ]);
    final explicitNumber = _firstInt(json, const <String>[
      'person_number',
      'person_no',
      'personNumber',
      'number',
    ]);
    final extractedProducts = _extractProducts(json);
    return KotPersonData(
      personId: personId ?? '',
      personNumber:
          explicitNumber ?? _numberFromPersonId(personId) ?? fallbackNumber,
      holdOrderIds: <int>{
        ..._extractOrderIds(json),
        ...extractedProducts
            .map((product) => product.holdOrderId)
            .whereType<int>(),
      }.toList(growable: false),
      products: extractedProducts,
    );
  }

  final String personId;
  final int personNumber;
  final List<int> holdOrderIds;
  final List<ProcessingProduct> products;
}

List<ProcessingProduct> _extractProducts(Map<String, dynamic> person) {
  final products = <ProcessingProduct>[];

  void visit(Object? value, {int? inheritedOrderId}) {
    if (value is List) {
      for (final item in value) {
        visit(item, inheritedOrderId: inheritedOrderId);
      }
      return;
    }
    if (value is! Map) return;
    final map = Map<String, dynamic>.from(value);
    final isProduct =
        map.containsKey('product_id') ||
        map.containsKey('product_name') ||
        map.containsKey('variant_code');
    if (isProduct) {
      if (map['hold_order_id'] == null && inheritedOrderId != null) {
        map['hold_order_id'] = inheritedOrderId;
      }
      products.add(ProcessingProduct.fromJson(map));
      return;
    }

    final nestedOrderId =
        _firstInt(map, const <String>['hold_order_id', 'order_id', 'id']) ??
        inheritedOrderId;
    for (final key in const <String>[
      'products',
      'items',
      'order',
      'orders',
      'hold_order',
      'hold_orders',
      'kot_order',
      'kot_orders',
      'processing_orders',
      'details',
    ]) {
      visit(map[key], inheritedOrderId: nestedOrderId);
    }
  }

  for (final key in const <String>[
    'products',
    'items',
    'order',
    'orders',
    'hold_order',
    'hold_orders',
    'kot_order',
    'kot_orders',
    'processing_orders',
    'details',
  ]) {
    visit(person[key]);
  }
  return products;
}

List<int> _extractOrderIds(Map<String, dynamic> person) {
  final ids = <int>{};
  for (final key in const <String>[
    'hold_order_id',
    'order_id',
    'processing_order_id',
  ]) {
    final parsed = _toInt(person[key]);
    if (parsed != null) ids.add(parsed);
  }
  for (final key in const <String>[
    'hold_order_ids',
    'order_ids',
    'processing_order_ids',
  ]) {
    final values = person[key];
    if (values is! List) continue;
    ids.addAll(values.map(_toInt).whereType<int>());
  }
  for (final key in const <String>[
    'order',
    'orders',
    'hold_order',
    'hold_orders',
    'kot_order',
    'kot_orders',
    'processing_orders',
  ]) {
    final value = person[key];
    final orders = value is List ? value : <Object?>[value];
    for (final order in orders.whereType<Map>()) {
      final map = Map<String, dynamic>.from(order);
      final parsed = _firstInt(map, const <String>[
        'hold_order_id',
        'order_id',
        'id',
      ]);
      if (parsed != null) ids.add(parsed);
    }
  }
  return ids.toList(growable: false);
}

List<Map<String, dynamic>> _personList(Map<String, dynamic> json) {
  final data = json['data'];
  for (final candidate in <Object?>[
    if (data is Map) data['persons'],
    if (data is Map) data['data'],
    data,
    json['persons'],
  ]) {
    if (candidate is List) {
      return candidate
          .map((item) {
            if (item is Map) return Map<String, dynamic>.from(item);
            return <String, dynamic>{'person_id': item};
          })
          .toList(growable: false);
    }
  }
  if (data is Map &&
      (data.containsKey('person_id') || data.containsKey('personId'))) {
    return <Map<String, dynamic>>[Map<String, dynamic>.from(data)];
  }
  return const <Map<String, dynamic>>[];
}

String? _firstNonEmpty(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final normalized = json[key]?.toString().trim();
    if (normalized != null && normalized.isNotEmpty) return normalized;
  }
  return null;
}

int? _firstInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

int? _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

int? _numberFromPersonId(String? personId) {
  if (personId == null) return null;
  final match = RegExp(r'-(\d+)$').firstMatch(personId);
  return match == null ? null : int.tryParse(match.group(1)!);
}

bool? _toBool(Object? value) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}
