import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/data/model/post_kot_model.dart';
import 'package:pick_my_snacks/src/data/model/remove_kot_quantity.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_order_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/remove_kot_quantity_repository.dart';
import 'package:pick_my_snacks/src/domain/usecase/remove_kot_quantity_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_kot_order_usecase.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';

void main() {
  test('builds the KOT quantity removal request', () {
    const request = RemoveKotQuantityRequest(
      orderId: 12,
      removeQuantity: 1,
      detailId: 91,
    );

    expect(ApiRoutes.rquantity, 'kot_hold_remove_quantity');
    expect(request.toFormFields(), {
      'order_id': 12,
      'detail_id': 91,
      'remove_quantity': 1,
    });
  });

  test('parses removed quantity and updated backend totals', () {
    final response = RemoveKotQuantityResponse.fromJson({
      'status': true,
      'message': 'Quantity removed',
      'data': {
        'product': {
          'detail_id': 91,
          'product_id': 101,
          'product_name': 'Burger',
          'previous_quantity': '2',
          'removed_quantity': '1',
          'remaining_quantity': '1',
          'remaining_unit_value': '1',
          'row_total': '180.00',
        },
        'order': {
          'id': 12,
          'order_id': 'KOT-12',
          'table_id': 3,
          'subtotal': '180.00',
          'gst': '9.00',
          'discount': '0.00',
          'charge': '0.00',
          'total': '189.00',
          'status': 'processing',
          'products': [
            {'id': 91, 'product_id': 101, 'quantity': '1pcs'},
          ],
        },
      },
    });

    expect(response.status, isTrue);
    expect(response.data?.product?.previousQuantity, 2);
    expect(response.data?.product?.removedQuantity, 1);
    expect(response.data?.product?.remainingQuantity, 1);
    expect(response.data?.order?.subtotal, 180);
    expect(response.data?.order?.gst, 9);
    expect(response.data?.order?.total, 189);
  });

  test('controller removes one sent quantity from local state only', () async {
    final quantityRepository = _FakeRemoveKotQuantityRepository();
    final controller = HomeController(
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      SaveKotOrderUseCase(_FakeKotOrderRepository()),
      null,
      null,
      RemoveKotQuantityUseCase(quantityRepository),
    );
    const product = Product(
      id: 101,
      name: 'Burger',
      unit: '1pcs',
      price: 180,
      image: '',
    );
    controller.takeKotTable(3, staffName: 'Arun');
    controller.addProduct(product);
    controller.addProduct(product);
    expect(await controller.saveKitchenOrder(staffId: 7), isTrue);

    expect(await controller.decrement(controller.cart.single), isTrue);

    expect(quantityRepository.requests, isEmpty);
    expect(controller.cart.single.quantity, 1);
    expect(controller.backendSubtotal.value, isNull);
    expect(controller.backendTotal.value, isNull);
    expect(controller.pendingKitchenItems, isEmpty);
  });
}

class _FakeKotOrderRepository implements KotOrderRepository {
  @override
  Future<KotOrderResponse> saveKotOrder(KotOrderRequest request) async {
    return const KotOrderResponse(
      status: true,
      data: KotOrderData(
        table: KotTable(id: 1, tableId: 3, isActive: true),
        order: KotOrder(
          id: 12,
          orderId: 'KOT-12',
          tableId: 3,
          products: <KotProduct>[
            KotProduct(id: 91, orderId: 12, productId: 101, quantity: 2),
          ],
        ),
      ),
    );
  }
}

class _FakeRemoveKotQuantityRepository implements RemoveKotQuantityRepository {
  final requests = <RemoveKotQuantityRequest>[];

  @override
  Future<RemoveKotQuantityResponse> removeKotQuantity(
    RemoveKotQuantityRequest request,
  ) async {
    requests.add(request);
    return const RemoveKotQuantityResponse(
      status: true,
      message: 'Quantity removed',
      data: RemoveKotQuantityData(
        product: RemovedKotQuantityProduct(
          detailId: 91,
          productId: 101,
          previousQuantity: 2,
          removedQuantity: 1,
          remainingQuantity: 1,
          remainingUnitValue: 1,
          rowTotal: 180,
        ),
        order: RemoveKotQuantityOrder(
          id: 12,
          subtotal: 180,
          gst: 9,
          total: 189,
          products: <RemoveKotQuantityOrderProduct>[
            RemoveKotQuantityOrderProduct(id: 91, productId: 101),
          ],
        ),
      ),
    );
  }
}
