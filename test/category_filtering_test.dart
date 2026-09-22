import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/cart_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';

void main() {
  setUp(() {
    Get.reset();
    Get.put(CartController());
  });
  tearDown(() => Get.reset());
  test('Category filtering filters products case-insensitively', () {
    final controller = HomeController();
    controller.products.assignAll([
      const Product(
        id: 1,
        name: 'Kara Mixture',
        unit: '500g',
        price: 150,
        image: '',
        category: 'Mixture',
      ),
      const Product(
        id: 2,
        name: 'Sweet Laddu',
        unit: '250g',
        price: 100,
        image: '',
        category: 'Sweets & Chocolates',
      ),
    ]);

    // Products stay hidden until a category is selected
    expect(controller.categoryFilteredProducts, isEmpty);

    // Select 'Mixture'
    controller.selectCategory('Mixture');
    expect(controller.categoryFilteredProducts.length, 1);
    expect(controller.categoryFilteredProducts.first.name, 'Kara Mixture');

    // Select 'Sweets' (partial/case-insensitive match with 'Sweets & Chocolates')
    controller.selectCategory('Sweets');
    expect(controller.categoryFilteredProducts.length, 1);
    expect(controller.categoryFilteredProducts.first.name, 'Sweet Laddu');

    // Clear category
    controller.clearSelectedCategory();
    expect(controller.categoryFilteredProducts, isEmpty);
  });
}
