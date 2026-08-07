class TableListResponse {
  const TableListResponse({this.status, this.message, this.data});

  factory TableListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return TableListResponse(
      status: _toBool(json['status']),
      message: json['message']?.toString(),
      data: rawData is List
          ? rawData
                .whereType<Map>()
                .map(
                  (item) => TableData.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : <TableData>[],
    );
  }

  final bool? status;
  final String? message;
  final List<TableData>? data;

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'data': data?.map((item) => item.toJson()).toList(),
  };
}

class TableData {
  const TableData({this.id, this.branchId, this.tableId});

  factory TableData.fromJson(Map<String, dynamic> json) {
    return TableData(
      id: _toInt(json['id']),
      branchId: _toInt(json['branch_id']),
      tableId: _toInt(json['table_id']),
    );
  }

  final int? id;
  final int? branchId;
  final int? tableId;

  int? get displayNumber => tableId ?? id;

  Map<String, dynamic> toJson() => {
    'id': id,
    'branch_id': branchId,
    'table_id': tableId,
  };
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
