import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/data/model/get_product.dart' as api;
import 'package:pick_my_snacks/src/presentation/controller/homescreen/cart_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';

void main() {
  setUp(() => Get.put(CartController()));
  tearDown(() => Get.reset());
  test('category API preserves GST rate and included mode', () {
    final product = api.Data.fromJson({
      'id': 501,
      'tax': '5.00',
      'tax_mode': 'include',
    });
    expect(product.tax, 5);
    expect(product.taxMode, 'include');
  });
  test('included GST is broken out without increasing the product price', () {
    final controller = HomeController();
    controller.flow.value = PosFlow.categoryBilling;
    controller.cart.add(
      CartItem(
        product: const Product(
          id: 501,
          name: 'Plum Cake',
          unit: 'pcs',
          image: '',
          price: 250,
          taxRate: 5,
          taxMode: 'include',
        ),
      ),
    );
    expect(controller.tax, closeTo(11.9047619, 0.000001));
    expect(controller.subtotal, closeTo(238.0952381, 0.000001));
    expect(controller.total, closeTo(250, 0.000001));
    expect(controller.cartItemsTotal, closeTo(250, 0.000001));
    controller.cart.single.quantity = 2;
    expect(controller.tax, closeTo(23.8095238, 0.000001));
    expect(controller.total, closeTo(500, 0.000001));
    controller.backendGst.value = 23.81;
    controller.backendSubtotal.value = 476.19;
    controller.backendTotal.value = 500;
    expect(controller.tax, 23.81);
    expect(controller.total, 500);
  });
  test('exclusive GST is added and no-tax products add no GST', () {
    final controller = HomeController();
    controller.flow.value = PosFlow.categoryBilling;
    controller.cart.add(
      CartItem(
        product: const Product(
          id: 1,
          name: 'Cake',
          unit: 'pcs',
          image: '',
          price: 100,
          taxRate: 5,
          taxMode: 'exclude',
        ),
      ),
    );
    controller.cart.add(
      CartItem(
        product: const Product(
          id: 2,
          name: 'Tea',
          unit: 'pcs',
          image: '',
          price: 15,
          taxRate: 5,
          taxMode: 'none',
        ),
      ),
    );
    expect(controller.subtotal, 115);
    expect(controller.tax, 5);
    expect(controller.total, 120);
  });
}
