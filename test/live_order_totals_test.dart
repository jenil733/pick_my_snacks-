import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/data/model/get_staff.dart';
import 'package:pick_my_snacks/src/data/model/save_order.dart';
import 'package:pick_my_snacks/src/domain/repository/order_repository.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_order_usecase.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/staff/staff_controller.dart';

void main() {
  tearDown(Get.reset);

  test(
    'syncs API totals after a cart change and saves the full cart',
    () async {
      final repository = _FakeOrderRepository();
      final staffController = Get.put(StaffController());
      staffController.selectedStaff.value = const StaffData(id: 7, name: 'Sam');
      final controller = HomeController(null, SaveOrderUseCase(repository))
        ..onInit();

      controller.addProduct(controller.products[1]);
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(repository.requests, hasLength(1));
      expect(repository.requests.single.staffId, 7);
      expect(
        repository.requests.single.products,
        hasLength(controller.cart.length),
      );
      expect(
        repository.requests.single.products.fold<num>(
          0,
          (sum, item) => sum + item.quantity,
        ),
        controller.itemCount,
      );
      expect(controller.subtotal, 222.22);
      expect(controller.tax, 11.11);
      expect(controller.total, 233.33);

      final saved = await controller.saveOrder(staffId: 7);

      expect(saved, isTrue);
      expect(repository.requests, hasLength(2));
      expect(
        repository.requests.last.products,
        hasLength(controller.cart.length),
      );
      expect(
        repository.requests.last.products.fold<num>(
          0,
          (sum, item) => sum + item.quantity,
        ),
        controller.itemCount,
      );
      controller.onClose();
    },
  );
}

class _FakeOrderRepository implements OrderRepository {
  final requests = <SaveOrderRequest>[];

  @override
  Future<SaveOrderResponse> saveOrder(SaveOrderRequest request) async {
    requests.add(request);
    return const SaveOrderResponse(
      status: true,
      data: SaveOrderData(
        order: SavedOrder(
          id: 1,
          orderId: 'ORD0001',
          subtotal: 222.22,
          gst: 11.11,
          total: 233.33,
        ),
      ),
    );
  }
}
