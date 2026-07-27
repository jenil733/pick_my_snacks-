import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/data/model/get_delete.dart';

void main() {
  test('builds the delete endpoint with the selected order ID', () {
    expect(ApiRoutes.deleteHoldBill(15), 'delete_hold_bill/15');
    expect(ApiRoutes.deleteHoldBill(38), 'delete_hold_bill/38');
  });

  test('parses a successful delete response', () {
    final response = DeleteHeldBillResponse.fromJson({
      'status': true,
      'message': 'Held bill deleted successfully',
    });

    expect(response.status, isTrue);
    expect(response.message, 'Held bill deleted successfully');
  });
}
