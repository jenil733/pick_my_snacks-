import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_snacks/src/data/model/save_order.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';

void main() {
  test('builds indexed product fields expected by save_order', () {
    const request = SaveOrderRequest(
      staffId: 1,
      paymentMode: 'cash',
      products: [
        SaveOrderProductRequest(
          productId: 3,
          quantity: 2,
          unitValue: 0.56,
          unit: 'kg',
        ),
        SaveOrderProductRequest(
          productId: 6,
          quantity: 1,
          unitValue: 2,
          unit: 'pcs',
        ),
      ],
    );

    final fields = request.toFormFields();

    expect(fields['products[0][product_id]'], 3);
    expect(fields['products[0][qty]'], '2kg');
    expect(fields['products[0][unit_value]'], 0.56);
    expect(fields['products[0][unit]'], 'kg');
    expect(fields['products[0][is_kot]'], 0);
    expect(fields['products[1][product_id]'], 6);
    expect(fields['products[1][qty]'], '1pcs');
    expect(fields['products[1][unit_value]'], 2);
    expect(fields['products[1][unit]'], 'pcs');
    expect(fields['products[1][is_kot]'], 0);
    expect(fields['discount_type'], 'none');
    expect(fields['is_kot'], 0);
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

  test('formats and exposes a decimal kilogram unit value', () {
    final item = CartItem(
      product: const Product(
        id: 3,
        name: 'Mixture',
        unit: 'kg',
        price: 200,
        image: '',
      ),
      manualWeightKg: 0.5,
    );

    expect(item.displayUnit, '0.5kg');
    expect(item.total, 100);
    expect(item.orderQuantity, 0.5);
    expect(item.apiUnitValue, 0.5);
    expect(item.apiUnit, 'kg');

    item.quantity = 2;
    expect(item.total, 200);
    expect(item.orderQuantity, 1.0);
  });

  test('formats API quantities with a required unit suffix', () {
    const kilograms = SaveOrderProductRequest(
      productId: 1,
      quantity: 0.25,
      unit: 'kg',
    );
    const pieces = SaveOrderProductRequest(productId: 2, quantity: 2);
    const singularPiece = SaveOrderProductRequest(
      productId: 3,
      quantity: 1,
      unit: 'pc',
    );

    expect(kilograms.apiQuantity, '0.25kg');
    expect(pieces.apiQuantity, '2pcs');
    expect(singularPiece.apiQuantity, '1pcs');
  });

  test('does not convert a fractional piece quantity to kilograms', () {
    final controller = HomeController();
    final item = CartItem(
      product: const Product(
        id: 3,
        name: 'dfdf',
        unit: 'pcs',
        price: 10,
        image: '',
      ),
    );
    controller.cart.add(item);

    final error = controller.setItemAmount(item, 0.06);

    expect(error, 'Enter a whole-number quantity for pcs.');
    expect(item.quantity, 1);
    expect(item.manualWeightKg, isNull);
    expect(item.apiUnit, 'pcs');
    expect(
      SaveOrderProductRequest(
        productId: item.product.id,
        quantity: item.orderQuantity,
        unit: item.apiUnit,
      ).apiQuantity,
      '1pcs',
    );
  });

  test('splits piece and litre product units for the API', () {
    final pieces = CartItem(
      product: const Product(
        id: 4,
        name: 'Eggs',
        unit: '6pcs',
        price: 60,
        image: '',
      ),
    );
    final litres = CartItem(
      product: const Product(
        id: 5,
        name: 'Oil',
        unit: '0.5lt',
        price: 90,
        image: '',
      ),
    );

    expect(pieces.apiUnitValue, 6);
    expect(pieces.apiUnit, 'pcs');
    expect(litres.apiUnitValue, 0.5);
    expect(litres.apiUnit, 'lt');
  });
}
