import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_snacks/src/data/model/get_delete.dart';
import 'package:pick_my_snacks/src/data/model/get_hold.dart';
import 'package:pick_my_snacks/src/data/model/get_resume.dart';
import 'package:pick_my_snacks/src/domain/repository/delete_held_bill_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/get_hold_orders_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/resume_order_repository.dart';
import 'package:pick_my_snacks/src/domain/usecase/delete_held_bill_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_hold_orders_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/resume_order_usecase.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';

void main() {
  test(
    'backend held-order response replaces local cards and stays deleted',
    () async {
      final getRepository = _FakeGetHoldOrdersRepository();
      final deleteRepository = _FakeDeleteHeldBillRepository();
      final controller = HomeController(
        null,
        null,
        null,
        GetHoldOrdersUseCase(getRepository),
        null,
        DeleteHeldBillUseCase(deleteRepository),
      );
      controller.heldBills.add(
        HeldBill(id: 999, createdAt: DateTime(2026), items: const []),
      );

      await controller.getHoldOrders();

      expect(controller.usesBackendHeldOrders, isTrue);
      expect(controller.heldBills, isEmpty);
      expect(controller.heldOrderSummaries.map((order) => order.id), [82, 81]);

      final deleted = await controller.deleteHeldOrder(
        controller.heldOrderSummaries.first,
      );

      expect(deleted, isTrue);
      expect(deleteRepository.orderIds, [82]);
      expect(controller.heldOrderSummaries.map((order) => order.id), [81]);
      expect(controller.heldBills, isEmpty);
      expect(getRepository.callCount, 2);
    },
  );

  test('restores weight from unit_value when resumed qty is one', () async {
    final controller = HomeController(
      null,
      null,
      null,
      null,
      ResumeOrderUseCase(_FakeResumeOrderRepository()),
    );

    final resumed = await controller.resumeHeldOrder(
      const HeldOrderSummary(id: 12, orderId: 'ORD0012'),
    );

    expect(resumed, isTrue);
    expect(controller.cart, hasLength(1));
    expect(controller.cart.single.quantity, 1);
    expect(controller.cart.single.manualWeightKg, 0.56);
    expect(controller.cart.single.editableAmount, 0.56);
    expect(controller.cart.single.apiUnit, 'kg');
  });
}

class _FakeResumeOrderRepository implements ResumeOrderRepository {
  @override
  Future<ResumeOrderResponse> resumeOrder(int orderId) async {
    return const ResumeOrderResponse(
      status: true,
      data: ResumeOrderData(
        bill: ResumedBill(id: 12, orderId: 'ORD0012'),
        products: [
          ResumedProduct(
            productId: 3,
            productName: 'Mixture',
            price: 200,
            qty: 1,
            unitValue: 0.56,
            unit: 'kg',
          ),
        ],
      ),
    );
  }
}

class _FakeGetHoldOrdersRepository implements GetHoldOrdersRepository {
  int callCount = 0;

  @override
  Future<GetHoldOrdersResponse> getHoldOrders() async {
    callCount++;
    return const GetHoldOrdersResponse(
      status: true,
      data: [
        HeldOrderSummary(
          id: 82,
          orderId: '82',
          itemsCount: 1,
          total: 15,
          status: 'hold',
        ),
        HeldOrderSummary(
          id: 81,
          orderId: '81',
          itemsCount: 2,
          total: 790,
          status: 'hold',
        ),
      ],
    );
  }
}

class _FakeDeleteHeldBillRepository implements DeleteHeldBillRepository {
  final orderIds = <int>[];

  @override
  Future<DeleteHeldBillResponse> deleteHeldBill(int orderId) async {
    orderIds.add(orderId);
    return const DeleteHeldBillResponse(status: true);
  }
}
