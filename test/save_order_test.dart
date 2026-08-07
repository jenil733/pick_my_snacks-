import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_snacks/src/data/model/save_order.dart';

void main() {
  test('builds indexed product fields expected by save_order', () {
    const request = SaveOrderRequest(
      staffId: 1,
      paymentMode: 'cash',
      products: [
        SaveOrderProductRequest(productId: 3, quantity: 2),
        SaveOrderProductRequest(productId: 6, quantity: 1),
      ],
    );

    final fields = request.toFormFields();

    expect(fields['products[0][product_id]'], 3);
    expect(fields['products[0][qty]'], 2);
    expect(fields['products[1][product_id]'], 6);
    expect(fields['products[1][qty]'], 1);
    expect(fields['discount_type'], 'none');
    expect(fields, isNot(contains('gst')));
    expect(fields, isNot(contains('subtotal')));
    expect(fields, isNot(contains('total')));
    expect(fields, isNot(contains('products[0][quantity]')));
    expect(fields, isNot(contains('products[0][product_quantity]')));
    expect(fields, isNot(contains('discount_value')));
    expect(fields, isNot(contains('charge')));
  });

  test('adds applied discount and charge fields to save_order', () {
    const request = SaveOrderRequest(
      staffId: 1,
      paymentMode: 'cash',
      discountType: 'percentage',
      discountValue: 10,
      offer: 'Festival offer',
      discountReason: 'Promotion',
      charge: 25,
      chargeReason: 'Delivery',
      products: [SaveOrderProductRequest(productId: 3, quantity: 2)],
    );

    final fields = request.toFormFields();

    expect(fields['discount_type'], 'percentage');
    expect(fields['discount_value'], 10);
    expect(fields['offer'], 'Festival offer');
    expect(fields['discount_reason'], 'Promotion');
    expect(fields['charge'], 25);
    expect(fields['charge_reason'], 'Delivery');
  });
}
