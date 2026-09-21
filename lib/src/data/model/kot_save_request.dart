class KotSaveRequest {
  const KotSaveRequest({
    required this.tableId,
    this.staffId,
    this.paymentMode,
    this.productIds = const <int>[],
    this.personId,
  });

  final int tableId;
  final int? staffId;
  final String? paymentMode;
  final List<int> productIds;
  final String? personId;

  Map<String, dynamic> toFormFields() {
    final fields = <String, dynamic>{'table_id': tableId};
    if (staffId != null) fields['staff_id'] = staffId;
    final normalizedPaymentMode = paymentMode?.trim();
    if (normalizedPaymentMode != null && normalizedPaymentMode.isNotEmpty) {
      fields['payment_mode'] = normalizedPaymentMode;
    }
    final normalizedPersonId = personId?.trim();
    if (normalizedPersonId != null && normalizedPersonId.isNotEmpty) {
      fields['person_id'] = normalizedPersonId;
    }
    for (var index = 0; index < productIds.length; index++) {
      fields['products[$index][product_id]'] = productIds[index];
    }
    return fields;
  }
}
