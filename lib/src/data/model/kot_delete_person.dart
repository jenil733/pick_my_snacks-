class KotDeletePersonResponse {
  const KotDeletePersonResponse({this.status, this.message});

  factory KotDeletePersonResponse.fromJson(Map<String, dynamic> json) {
    return KotDeletePersonResponse(
      status: _toBool(json['status']),
      message: json['message']?.toString(),
    );
  }

  final bool? status;
  final String? message;
}

bool? _toBool(Object? value) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}
