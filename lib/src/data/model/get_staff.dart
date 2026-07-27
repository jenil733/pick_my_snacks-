class StaffListResponse {
  const StaffListResponse({this.status, this.message, this.data});

  factory StaffListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return StaffListResponse(
      status: _toBool(json['status']),
      message: json['message']?.toString(),
      data: rawData is List
          ? rawData
                .whereType<Map>()
                .map(
                  (item) => StaffData.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : <StaffData>[],
    );
  }

  final bool? status;
  final String? message;
  final List<StaffData>? data;

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'data': data?.map((item) => item.toJson()).toList(),
  };
}

class StaffData {
  const StaffData({this.id, this.name, this.userId, this.designation});

  factory StaffData.fromJson(Map<String, dynamic> json) {
    return StaffData(
      id: _toInt(json['id']),
      name: json['name']?.toString(),
      userId: json['user_id']?.toString(),
      designation: json['designation']?.toString(),
    );
  }

  final int? id;
  final String? name;
  final String? userId;
  final String? designation;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'user_id': userId,
    'designation': designation,
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
