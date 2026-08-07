class TableStatusResponse {
  const TableStatusResponse({this.status, this.message, this.data});

  factory TableStatusResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return TableStatusResponse(
      status: _toBool(json['status']),
      message: json['message']?.toString(),
      data: rawData is List
          ? rawData
                .whereType<Map>()
                .map(
                  (item) =>
                      TableStatusData.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : <TableStatusData>[],
    );
  }

  final bool? status;
  final String? message;
  final List<TableStatusData>? data;

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'data': data?.map((item) => item.toJson()).toList(),
  };
}

class TableStatusData {
  const TableStatusData({
    this.id,
    this.tableId,
    this.tableStatus,
    this.isOccupied,
  });

  factory TableStatusData.fromJson(Map<String, dynamic> json) {
    return TableStatusData(
      id: _toInt(json['id']),
      tableId: _toInt(json['table_id']),
      tableStatus: json['table_status']?.toString(),
      isOccupied: _toInt(json['is_occupied']),
    );
  }

  final int? id;
  final int? tableId;
  final String? tableStatus;
  final int? isOccupied;

  bool get occupied {
    final normalized = tableStatus?.trim().toLowerCase();
    if (const {'free', 'available', 'vacant', 'open'}.contains(normalized)) {
      return false;
    }
    if (const {
      'occupied',
      'taken',
      'busy',
      'processing',
      'reserved',
    }.contains(normalized)) {
      return true;
    }
    return isOccupied == 1;
  }

  String get displayStatus {
    final raw = tableStatus?.trim();
    if (raw == null || raw.isEmpty) return occupied ? 'Occupied' : 'Free';
    return raw
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'table_id': tableId,
    'table_status': tableStatus,
    'is_occupied': isOccupied,
  };
}

int? _toInt(Object? value) {
  if (value is int) return value;
  if (value is bool) return value ? 1 : 0;
  return int.tryParse(value?.toString() ?? '');
}

bool? _toBool(Object? value) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}
