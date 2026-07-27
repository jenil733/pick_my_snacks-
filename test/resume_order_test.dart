import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/data/model/get_resume.dart';

void main() {
  test('builds the resume endpoint with the selected order ID', () {
    expect(ApiRoutes.resumeHoldBill(11), 'resume_hold_bill/11');
    expect(ApiRoutes.resumeHoldBill(42), 'resume_hold_bill/42');
  });

  test('parses a resumed bill and its products', () {
    final response = ResumeOrderResponse.fromJson({
      'status': true,
      'message': 'Order resumed',
      'data': {
        'bill': {
          'id': 11,
          'order_id': 'ORD0011',
          'gst': '12.50',
          'total': '262.50',
          'payment_mode': 'cash',
          'status': 'active',
        },
        'products': [
          {
            'id': 99,
            'product_id': 3,
            'product_name': 'Snack',
            'product_code': 'PRO3',
            'price': '250.00',
            'qty': 2,
            'unit_value': 1,
            'unit': 'pcs',
          },
        ],
      },
    });

    expect(response.status, isTrue);
    expect(response.data!.bill!.orderId, 'ORD0011');
    expect(response.data!.bill!.gst, 12.5);
    expect(response.data!.products, hasLength(1));
    expect(response.data!.products!.single.productId, 3);
    expect(response.data!.products!.single.qty, 2);
  });
}
