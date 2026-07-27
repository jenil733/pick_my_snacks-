import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_snacks/src/data/model/hold_order.dart';
import 'package:pick_my_snacks/src/data/model/save_order.dart';

void main() {
  test('builds indexed product fields expected by hold_save_order', () {
    const request = HoldOrderRequest(
      staffId: 1,
      paymentMode: 'cash',
      products: [
        SaveOrderProductRequest(productId: 3, quantity: 2),
        SaveOrderProductRequest(productId: 6, quantity: 1),
      ],
    );

    final fields = request.toFormFields();

    expect(fields['staff_id'], 1);
    expect(fields['discount_type'], 'none');
    expect(fields['products[0][product_id]'], 3);
    expect(fields['products[0][qty]'], 2);
    expect(fields['products[1][product_id]'], 6);
    expect(fields['products[1][qty]'], 1);
    expect(fields, isNot(contains('gst')));
    expect(fields, isNot(contains('subtotal')));
    expect(fields, isNot(contains('total')));
  });
}
