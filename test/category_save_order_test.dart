import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/data/model/save_order.dart';
import 'package:pick_my_snacks/src/domain/repository/order_repository.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_order_usecase.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/cart_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';

class FakeOrderRepository implements OrderRepository {
  SaveOrderResponse response = const SaveOrderResponse(
    status: false,
    message: 'Invalid product',
  );
  bool fail = false;
  SaveOrderRequest? lastRequest;
  @override
  Future<SaveOrderResponse> saveOrder(SaveOrderRequest request) async {
    lastRequest = request;
    if (fail) throw Exception('offline');
    return response;
  }
}

void main() {
  setUp(() => Get.put(CartController()));
  tearDown(() => Get.reset());
  test('save uses database ID even when product code is numeric', () async {
    final repository = FakeOrderRepository();
    final controller = HomeController(null, SaveOrderUseCase(repository));
    controller.flow.value = PosFlow.categoryBilling;
    controller.cart.add(
      CartItem(
        product: const Product(
          id: 155,
          productId: '900001',
          name: 'Tea',
          unit: 'pcs',
          price: 15,
          image: '',
        ),
      ),
    );
    await controller.saveOrder(staffId: 1);
    expect(
      repository.lastRequest!.toFormFields()['products[0][product_id]'],
      155,
    );
  });
  test(
    'category receipt requires server order confirmation and keeps failed cart',
    () async {
      final repository = FakeOrderRepository();
      final controller = HomeController(null, SaveOrderUseCase(repository));
      controller.flow.value = PosFlow.categoryBilling;
      controller.cart.add(
        CartItem(
          product: const Product(
            id: 155,
            name: 'Tea',
            unit: 'pcs',
            price: 15,
            image: '',
          ),
        ),
      );
      expect(await controller.saveOrder(staffId: 1), isFalse);
      expect(controller.saveOrderError.value, 'Invalid product');
      expect(controller.savedOrderNumber.value, isNull);
      expect(controller.cart, hasLength(1));
      repository.fail = true;
      expect(await controller.saveOrder(staffId: 1), isFalse);
      expect(controller.savedOrderNumber.value, isNull);
      repository.fail = false;
      repository.response = const SaveOrderResponse(status: true);
      expect(await controller.saveOrder(staffId: 1), isFalse);
      expect(controller.savedOrderNumber.value, isNull);
      repository.response = SaveOrderResponse.fromJson({
        'status': true,
        'data': {
          'order': {'order_id': 'BILL-123'},
        },
      });
      expect(await controller.saveOrder(staffId: 1), isTrue);
      expect(controller.savedOrderNumber.value, 'BILL-123');
    },
  );
  test('missing save service cannot report a successful save', () async {
    final controller = HomeController();
    expect(await controller.saveOrder(staffId: 1), isFalse);
    expect(controller.saveOrderError.value, isNotNull);
  });
}
