class LoginResponse {
  const LoginResponse({this.status, this.message, this.data});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return LoginResponse(
      status: _toBool(json['status']),
      message: json['message']?.toString(),
      data: rawData is Map
          ? LoginData.fromJson(Map<String, dynamic>.from(rawData))
          : null,
    );
  }

  final bool? status;
  final String? message;
  final LoginData? data;

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    if (data != null) 'data': data!.toJson(),
  };
}

class LoginData {
  const LoginData({
    this.token,
    this.tokenType,
    this.counterId,
    this.branchId,
    this.type,
    this.counterName,
    this.loginId,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    final rawStaff = json['staff'];
    final staff = rawStaff is Map
        ? Map<String, dynamic>.from(rawStaff)
        : <String, dynamic>{};

    return LoginData(
      token:
          json['access_token']?.toString() ??
          json['token']?.toString() ??
          json['bearer_token']?.toString(),
      tokenType: json['token_type']?.toString(),
      counterId: _toInt(staff['counter_id'] ?? json['counter_id']),
      branchId: _toInt(staff['branch_id'] ?? json['branch_id']),
      type: (staff['type'] ?? json['type'])?.toString(),
      counterName: (staff['counter_name'] ?? json['counter_name'])?.toString(),
      loginId: (staff['login_id'] ?? json['login_id'])?.toString(),
    );
  }

  final String? token;
  final String? tokenType;
  final int? counterId;
  final int? branchId;
  final String? type;
  final String? counterName;
  final String? loginId;

  Map<String, dynamic> toJson() => {
    'access_token': token,
    'token_type': tokenType,
    'staff': {
      'counter_id': counterId,
      'branch_id': branchId,
      'type': type,
      'counter_name': counterName,
      'login_id': loginId,
    },
  };
}

int? _toInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

bool? _toBool(Object? value) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1' || normalized == 'success') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'failed') {
    return false;
  }
  return null;
}
