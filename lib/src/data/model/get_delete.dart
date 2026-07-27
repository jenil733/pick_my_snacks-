class DeleteHeldBillResponse {
  const DeleteHeldBillResponse({this.status, this.message});

  factory DeleteHeldBillResponse.fromJson(Map<String, dynamic> json) {
    return DeleteHeldBillResponse(
      status: _toBool(json['status']),
      message: json['message']?.toString(),
    );
  }

  final bool? status;
  final String? message;

  Map<String, dynamic> toJson() => {'status': status, 'message': message};
}

bool? _toBool(Object? value) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}
