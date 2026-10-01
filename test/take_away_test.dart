import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide FormData, Response;
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/core/services/local_storage.dart';
import 'package:pick_my_snacks/src/data/model/get_staff.dart';
import 'package:pick_my_snacks/src/data/model/remove_kot_product.dart';
import 'package:pick_my_snacks/src/data/model/remove_kot_quantity.dart';
import 'package:pick_my_snacks/src/data/model/save_order.dart';
import 'package:pick_my_snacks/src/data/model/take_away_change_quantity.dart';
import 'package:pick_my_snacks/src/data/model/take_away_hold.dart';
import 'package:pick_my_snacks/src/data/model/take_away_processing.dart';
import 'package:pick_my_snacks/src/data/model/take_away_save_order.dart';
import 'package:pick_my_snacks/src/data/repository/take_away_processing_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/take_away_change_quantity_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/take_away_remove_product_repository_impl.dart';
import 'package:pick_my_snacks/src/domain/repository/order_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_completed_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_completed_view_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_hold_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_processing_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_change_quantity_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_remove_product_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_save_order_repository.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_take_away_completed_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_take_away_completed_view_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_take_away_processing_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_order_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/take_away_hold_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/take_away_change_quantity_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/take_away_remove_product_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/take_away_save_order_usecase.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/cart_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/staff/staff_controller.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/bill_summary_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/take_away_orders_panel.dart';
import 'package:pick_my_snacks/src/printing/kitchen_printer.dart';
import 'package:pick_my_snacks/src/printing/printer_manager.dart';
import 'package:pick_my_snacks/src/printing/printer_repository.dart';
import 'package:pick_my_snacks/src/services/receipt_printer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => Get.put(CartController()));
  tearDown(Get.reset);

  test('take-away quantity change posts the quantity to remove', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final storage = await LocalStorageService.initialize();
    final dio = Dio();
    RequestOptions? capturedRequest;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const <String, dynamic>{
                'status': true,
                'message': 'Quantity changed',
              },
            ),
          );
        },
      ),
    );
    final repository = TakeAwayChangeQuantityRepositoryImpl(
      ApiService(storage: storage, dio: dio),
    );

    final response = await repository.changeTakeAwayQuantity(
      const TakeAwayChangeQuantityRequest(
        orderId: 623,
        detailId: 955,
        removeQuantity: 0.5,
      ),
    );

    expect(capturedRequest?.method, 'POST');
    expect(capturedRequest?.path, ApiRoutes.takeAwayChangeQuantity);
    final fields = Map<String, String>.fromEntries(
      (capturedRequest?.data as FormData).fields,
    );
    expect(fields, <String, String>{
      'order_id': '623',
      'detail_id': '955',
      'remove_quantity': '0.5',
    });
    expect(response.status, isTrue);
  });

  test(
    'take-away removal posts order and detail IDs as multipart fields',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final storage = await LocalStorageService.initialize();
      final dio = Dio();
      RequestOptions? capturedRequest;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedRequest = options;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: const <String, dynamic>{
                  'status': true,
                  'message': 'Product removed',
                },
              ),
            );
          },
        ),
      );
      final repository = TakeAwayRemoveProductRepositoryImpl(
        ApiService(storage: storage, dio: dio),
      );

      final response = await repository.removeTakeAwayProduct(
        const RemoveKotProductRequest(orderId: 614, detailId: 937),
      );

      expect(capturedRequest?.method, 'POST');
      expect(capturedRequest?.path, ApiRoutes.takeAwayRemoveProduct);
      final fields = Map<String, String>.fromEntries(
        (capturedRequest?.data as FormData).fields,
      );
      expect(fields, <String, String>{'order_id': '614', 'detail_id': '937'});
      expect(response.status, isTrue);
    },
  );

  test(
    'processing detail uses the view endpoint and multipart hold ID',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final storage = await LocalStorageService.initialize();
      final dio = Dio();
      RequestOptions? capturedRequest;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedRequest = options;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: const <String, dynamic>{
                  'status': true,
                  'data': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'id': 189,
                      'products': <Map<String, dynamic>>[
                        <String, dynamic>{
                          'product_id': 4,
                          'product_name': 'Snack',
                          'quantity': '1',
                        },
                      ],
                    },
                  ],
                },
              ),
            );
          },
        ),
      );
      final repository = TakeAwayProcessingRepositoryImpl(
        ApiService(storage: storage, dio: dio),
      );

      final response = await repository.getProcessingTakeAway(189);

      expect(capturedRequest?.method, 'GET');
      expect(capturedRequest?.path, ApiRoutes.takeAwayProcessingView(189));
      expect(capturedRequest?.queryParameters, isEmpty);
      final fields = Map<String, String>.fromEntries(
        (capturedRequest?.data as FormData).fields,
      );
      expect(fields, <String, String>{'hold_order_id': '189'});
      expect(response.orders.single.products.single.productId, 4);
    },
  );

  test('take away cart changes do not call the billing API', () async {
    final repository = _FakeOrderRepository();
    final staffController = Get.put(StaffController());
    staffController.selectedStaff.value = const StaffData(id: 7, name: 'Sam');
    final controller = HomeController(null, SaveOrderUseCase(repository))
      ..onInit()
      ..selectFlow(PosFlow.takeAway);

    controller.addProduct(controller.products.first);
    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(controller.flow.value, PosFlow.takeAway);
    expect(repository.requests, isEmpty);
    controller.onClose();
  });

  test('builds the take_away_hold multipart fields', () {
    const request = TakeAwayHoldRequest(
      staffId: 1,
      customerName: 'test',
      customerPhone: 'ans',
      paymentMode: 'cash',
      products: [
        SaveOrderProductRequest(
          productId: 4,
          quantity: 0.450,
          unit: 'kg',
          note: 'extra salt',
          isKot: false,
        ),
        SaveOrderProductRequest(
          productId: 5,
          quantity: 1,
          unit: 'pcs',
          isKot: true,
        ),
      ],
    );

    expect(request.toFormFields(), {
      'staff_id': 1,
      'user_id': '',
      'customer_name': 'test',
      'customer_phone': 'ans',
      'charge': 0.0,
      'payment_mode': 'cash',
      'status': '',
      'products[0][product_id]': 4,
      'products[0][qty]': '0.45kg',
      'products[0][note]': 'extra salt',
      'products[0][is_kot]': 0,
      'products[1][product_id]': 5,
      'products[1][qty]': '1pcs',
      'products[1][note]': '',
      'products[1][is_kot]': 0,
      'discount_type': '',
      'discount_value': '',
      'discount': 0,
      'offer': 0,
      'print_kitchen': 1,
    });
  });

  test('parses the take away hold KOT response', () {
    final response = TakeAwayHoldResponse.fromJson({
      'status': true,
      'message': 'take away order saved successfully.',
      'data': {
        'is_processing': 1,
        'order': {
          'id': 557,
          'order_id': 'KOT10438',
          'table_id': 0,
          'branch_id': 1,
          'staff_id': 3,
          'customer_name': 'Printer Test',
          'customer_phone': '9876543210',
          'subtotal': 1070.52,
          'gst': 49.37,
          'discount': 0,
          'charge': 0,
          'total': 1119.89,
          'payment_mode': 'cash',
          'status': 'take_away_processing',
          'billed_in': 'app',
          'products': [
            {
              'id': 821,
              'order_id': 557,
              'product_id': 4,
              'product_name': 'good day',
              'product_code': '1003',
              'variant_code': '1003',
              'mrp': '10.00',
              'price': '10.00',
              'quantity': 2,
              'note': 'Kitchen printer test',
              'unit_value': '2',
              'unit': 'pcs',
              'tax': '4.00',
              'row_total': '20.00',
              'is_kot': '0',
              'print_target': null,
              'printed_at': null,
              'created_at': '2026-09-30T09:22:47.000000Z',
              'updated_at': '2026-09-30T09:22:47.000000Z',
            },
            {
              'id': 823,
              'order_id': 557,
              'product_id': 1,
              'product_name': 'black forest',
              'quantity': 1,
              'is_kot': '1',
            },
          ],
        },
      },
    });

    expect(response.status, isTrue);
    expect(response.data?.isProcessing, isTrue);
    expect(response.data?.order?.id, 557);
    expect(response.data?.order?.orderId, 'KOT10438');
    expect(response.data?.order?.customerName, 'Printer Test');
    expect(response.data?.order?.status, 'take_away_processing');
    expect(response.data?.order?.products, hasLength(2));
    expect(response.data?.order?.products.first.note, 'Kitchen printer test');
    expect(response.data?.order?.products.first.isKot, isFalse);
    expect(response.data?.order?.products.last.isKot, isTrue);
    expect(response.data?.order?.products.first.printTarget, isNull);
  });

  test('builds the take_away_save_order multipart fields', () {
    const request = TakeAwaySaveOrderRequest(holdOrderIds: [159, 160]);

    expect(request.toFormFields(), {
      'hold_order_ids[0]': 159,
      'hold_order_ids[1]': 160,
    });
  });

  test('accepts a decimal weight for a gram product', () {
    final controller = HomeController()..selectFlow(PosFlow.takeAway);
    controller.addProduct(
      const Product(
        id: 44,
        name: 'Loose snack',
        unit: 'gram',
        price: 200,
        image: '',
      ),
    );
    final item = controller.cart.single;

    final error = controller.setItemAmount(item, 0.5);

    expect(error, isNull);
    expect(item.manualWeightKg, 0.5);
    expect(item.editableAmount, 0.5);
    expect(item.apiUnit, 'kg');
  });

  test('saved take-away weight change calls the quantity API', () async {
    final holdRepository = _FakeTakeAwayHoldRepository(
      includeProductDetails: true,
    );
    final quantityRepository = _FakeTakeAwayChangeQuantityRepository();
    Get.put(TakeAwayChangeQuantityUseCase(quantityRepository));
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
      null,
      null,
      null,
      null,
      TakeAwayHoldUseCase(holdRepository),
    )..selectFlow(PosFlow.takeAway);
    controller.addProduct(
      const Product(
        id: 4,
        name: 'Loose snack',
        unit: 'gram',
        price: 200,
        image: '',
      ),
    );
    controller.takeAwayCustomerName.value = 'Anu';
    controller.takeAwayCustomerPhone.value = '9876543210';
    expect(await controller.saveTakeAwayKitchenBill(staffId: 1), isTrue);
    final item = controller.cart.single;

    final error = await controller.applyItemAmount(item, 0.5);

    expect(error, isNull);
    expect(quantityRepository.requests, hasLength(1));
    expect(quantityRepository.requests.single.orderId, 1001);
    expect(quantityRepository.requests.single.detailId, 937);
    expect(quantityRepository.requests.single.removeQuantity, 0.5);
    expect(item.editableAmount, 0.5);
  });

  test('take-away minus button uses the change quantity API', () async {
    final quantityRepository = _FakeTakeAwayChangeQuantityRepository();
    Get.put(TakeAwayChangeQuantityUseCase(quantityRepository));
    final controller = HomeController()..selectFlow(PosFlow.takeAway);
    final item = CartItem(
      product: const Product(
        id: 4,
        name: 'Burger',
        unit: 'pcs',
        price: 100,
        image: '',
      ),
      quantity: 2,
      sentKitchenQuantity: 2,
      kotProductReferences: <KotProductReference>[
        const KotProductReference(orderId: 622, detailId: 952, quantity: 2),
      ],
    );
    controller.cart.add(item);

    final decremented = await controller.decrement(item);
    expect(
      decremented,
      isTrue,
      reason: controller.removeKotQuantityError.value,
    );

    expect(quantityRepository.requests, hasLength(1));
    expect(quantityRepository.requests.single.orderId, 622);
    expect(quantityRepository.requests.single.detailId, 952);
    expect(quantityRepository.requests.single.removeQuantity, 1);
    expect(item.quantity, 1);
  });

  test('take-away minus subtracts one from a saved weight', () async {
    final quantityRepository = _FakeTakeAwayChangeQuantityRepository();
    Get.put(TakeAwayChangeQuantityUseCase(quantityRepository));
    final controller = HomeController()..selectFlow(PosFlow.takeAway);
    final item = CartItem(
      product: const Product(
        id: 4,
        name: 'Loose snack',
        unit: 'kg',
        price: 100,
        image: '',
      ),
      manualWeightKg: 3,
      sentKitchenQuantity: 1,
      kotProductReferences: <KotProductReference>[
        const KotProductReference(orderId: 623, detailId: 955, quantity: 3),
      ],
    );
    controller.cart.add(item);

    final decremented = await controller.decrement(item);

    expect(
      decremented,
      isTrue,
      reason: controller.removeKotQuantityError.value,
    );
    expect(quantityRepository.requests, hasLength(1));
    expect(quantityRepository.requests.single.removeQuantity, 1);
    expect(item.editableAmount, 2);
  });

  test('take-away minus subtracts one from an unsaved weight', () async {
    final controller = HomeController()..selectFlow(PosFlow.takeAway);
    final item = CartItem(
      product: const Product(
        id: 4,
        name: 'Loose snack',
        unit: 'kg',
        price: 100,
        image: '',
      ),
      manualWeightKg: 3,
    );
    controller.cart.add(item);

    expect(await controller.decrement(item), isTrue);
    expect(item.editableAmount, 2);
  });

  test('removes a kitchen-sent take-away product with backend IDs', () async {
    final holdRepository = _FakeTakeAwayHoldRepository(
      includeProductDetails: true,
    );
    final removeRepository = _FakeTakeAwayRemoveProductRepository();
    Get.put(TakeAwayRemoveProductUseCase(removeRepository));
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
      null,
      null,
      null,
      null,
      TakeAwayHoldUseCase(holdRepository),
    )..selectFlow(PosFlow.takeAway);
    controller.addProduct(
      const Product(id: 4, name: 'Burger', unit: 'pcs', price: 100, image: ''),
    );
    controller.takeAwayCustomerName.value = 'Anu';
    controller.takeAwayCustomerPhone.value = '9876543210';

    expect(await controller.saveTakeAwayKitchenBill(staffId: 1), isTrue);
    final item = controller.cart.single;
    expect(item.kotProductReferences.single.orderId, 1001);
    expect(item.kotProductReferences.single.detailId, 937);

    expect(await controller.removeKotProduct(item), isTrue);
    expect(removeRepository.requests, hasLength(1));
    expect(removeRepository.requests.single.orderId, 1001);
    expect(removeRepository.requests.single.detailId, 937);
    expect(removeRepository.requests.single.personId, isNull);
    expect(controller.cart, isEmpty);
  });

  test('loads the current pending take-away order using its hold ID', () async {
    final repository = _FakeTakeAwayProcessingRepository();
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
      null,
      null,
      null,
      null,
      null,
      null,
      GetTakeAwayProcessingUseCase(repository),
    );
    controller.takeAwayHoldOrderId.value = 97;

    await controller.getTakeAwayProcessing();

    expect(repository.holdOrderIds, [97]);
    expect(controller.takeAwayProcessingOrders.single.id, 97);
    expect(controller.takeAwayProcessingOrders.single.customerName, 'Anu');
  });

  test('parses the pending take-away bill response', () {
    final response = TakeAwayProcessingResponse.fromJson({
      'status': true,
      'data': {
        'id': 162,
        'order_id': 'KOT10037',
        'customer_name': 'test',
        'customer_phone': 'ans',
        'staff_name': 'Staff',
        'products': [
          {
            'product_id': 4,
            'product_name': 'Snack',
            'quantity': '0.45',
            'unit': 'kg',
            'price': '600.00',
            'row_total': '135.00',
          },
        ],
      },
    });

    expect(response.orders.single.id, 162);
    expect(response.orders.single.staffName, 'Staff');
    expect(response.orders.single.products.single.quantity, '0.45');
    expect(response.orders.single.products.single.rowTotal, 135);
  });

  test('opens a pending bill in the take-away billing screen', () {
    final controller = HomeController();
    const order = TakeAwayProcessingOrder(
      id: 162,
      orderId: 'KOT10037',
      customerName: 'test',
      customerPhone: 'ans',
      products: [
        TakeAwayProcessingProduct(
          productId: 4,
          productName: 'Snack',
          quantity: '0.45',
          unit: 'kg',
          price: 600,
          rowTotal: 135,
        ),
      ],
    );

    controller.continuePendingTakeAwayOrder(order);

    expect(controller.flow.value, PosFlow.takeAway);
    expect(controller.takeAwayHoldOrderId.value, 162);
    expect(controller.takeAwayCustomerName.value, 'test');
    expect(controller.takeAwayCustomerPhone.value, 'ans');
    expect(controller.cart.single.product.id, 4);
    expect(controller.cart.single.manualWeightKg, 0.45);
  });

  test('loads completed take-away orders from the API', () async {
    final repository = _FakeTakeAwayCompletedRepository();
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
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      GetTakeAwayCompletedUseCase(repository),
    );
    controller.completedTakeAwayHoldIds.add(97);

    await controller.getTakeAwayCompleted();

    expect(repository.holdOrderIds, contains(97));
    expect(controller.completedTakeAwayOrders.single.id, 97);
  });

  test('loads a completed take-away order using both API IDs', () async {
    final repository = _FakeTakeAwayCompletedViewRepository();
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
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      GetTakeAwayCompletedViewUseCase(repository),
    );

    await controller.getCompletedTakeAwayView(233, 97);

    expect(repository.completedOrderIds, [233]);
    expect(repository.holdOrderIds, [97]);
    expect(controller.completedTakeAwayOrderView.value?.id, 233);
    expect(controller.completedTakeAwayOrderView.value?.holdOrderId, 97);
  });

  testWidgets('pending Close Bill restores the bill on the billing screen', (
    tester,
  ) async {
    final processingRepository = _FakeTakeAwayProcessingRepository();
    final saveRepository = _FakeTakeAwaySaveOrderRepository();
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
      null,
      null,
      null,
      null,
      null,
      TakeAwaySaveOrderUseCase(saveRepository),
      GetTakeAwayProcessingUseCase(processingRepository),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showTakeAwayOrdersPanel(
                context,
                controller,
                initialTab: TakeAwayOrdersTab.pending,
              ),
              child: const Text('Pending'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pending'));
    await tester.pumpAndSettle();
    expect(find.text('processing'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Close Bill'));
    await tester.pumpAndSettle();

    expect(find.text('Close Bill'), findsNothing);
    expect(controller.flow.value, PosFlow.takeAway);
    expect(controller.takeAwayHoldOrderId.value, 97);
    expect(controller.takeAwayCustomerName.value, 'Anu');
    expect(controller.cart.single.product.id, 4);
    expect(processingRepository.holdOrderIds, [97]);
    expect(controller.isTakeAwayOrderCompleted.value, isFalse);
    expect(saveRepository.requests, isEmpty);

    expect(await controller.completeTakeAwayOrder(), isTrue);
    expect(saveRepository.requests.single.holdOrderIds, [97]);
    expect(controller.isTakeAwayOrderCompleted.value, isTrue);
  });

  test('closes a selected pending take-away bill', () async {
    final repository = _FakeTakeAwaySaveOrderRepository();
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
      null,
      null,
      null,
      null,
      null,
      TakeAwaySaveOrderUseCase(repository),
    );
    const pendingOrder = TakeAwayProcessingOrder(
      id: 162,
      orderId: 'KOT10037',
      customerName: 'test',
      customerPhone: 'ans',
      status: 'processing',
    );
    controller.pendingTakeAwayHoldIds.add(162);
    controller.takeAwayProcessingOrders.add(pendingOrder);

    final closed = await controller.completeTakeAwayOrder(
      holdOrderId: 162,
      pendingOrder: pendingOrder,
    );

    expect(closed, isTrue);
    expect(repository.requests.single.holdOrderIds, [162]);
    expect(controller.takeAwayProcessingOrders, isEmpty);
    expect(controller.completedTakeAwayOrders.single.customerName, 'test');
  });

  test(
    'completes take-away when save response omits the final order',
    () async {
      final repository = _FakeTakeAwaySaveOrderWithoutOrderRepository();
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
        null,
        null,
        null,
        null,
        null,
        TakeAwaySaveOrderUseCase(repository),
      )..selectFlow(PosFlow.takeAway);
      controller.takeAwayHoldOrderId.value = 623;
      controller.takeAwayHoldOrderIds.assignAll(<int>[623]);
      controller.savedOrderNumber.value = 'TA-623';
      controller.backendSubtotal.value = 100;
      controller.backendGst.value = 5;
      controller.backendTotal.value = 105;

      expect(await controller.completeTakeAwayOrder(), isTrue);
      expect(controller.takeAwaySaveOrderError.value, isNull);
      expect(controller.completedTakeAwayOrder.value?.orderId, 'TA-623');
      expect(controller.completedTakeAwayOrder.value?.subtotal, 100);
      expect(controller.completedTakeAwayOrder.value?.gst, 5);
      expect(controller.completedTakeAwayOrder.value?.total, 105);
    },
  );

  test(
    'take away kitchen bill holds every product with kitchen flags',
    () async {
      final repository = _FakeTakeAwayHoldRepository();
      final saveRepository = _FakeTakeAwaySaveOrderRepository();
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
        null,
        null,
        null,
        null,
        TakeAwayHoldUseCase(repository),
        TakeAwaySaveOrderUseCase(saveRepository),
      )..selectFlow(PosFlow.takeAway);
      const burger = Product(
        id: 4,
        name: 'Burger',
        unit: 'kg',
        price: 100,
        image: '',
      );
      const tea = Product(
        id: 5,
        name: 'Tea',
        unit: 'pcs',
        price: 20,
        image: '',
      );
      controller.addProduct(burger);
      controller.addProduct(tea);
      controller.setItemAmount(controller.cart.first, 0.45);
      controller.updateItemNotes(controller.cart.first, 'extra salt');
      controller.takeAwayCustomerName.value = 'Anu';
      controller.takeAwayCustomerPhone.value = '9876543210';
      expect(repository.requests, isEmpty);

      expect(
        await controller.saveTakeAwayKitchenBill(
          staffId: 1,
          selectedOnly: false,
          markAsKitchen: false,
        ),
        isTrue,
      );

      expect(repository.requests, hasLength(1));
      expect(repository.requests.single.products, hasLength(2));
      expect(repository.requests.single.products[0].productId, 4);
      expect(repository.requests.single.products[0].apiQuantity, '0.45kg');
      expect(repository.requests.single.products[0].note, 'extra salt');
      expect(repository.requests.single.products[0].isKot, isFalse);
      expect(repository.requests.single.products[1].productId, 5);
      expect(repository.requests.single.products[1].apiQuantity, '1pcs');
      expect(repository.requests.single.products[1].isKot, isFalse);
      expect(repository.requests.single.customerName, 'Anu');
      expect(repository.requests.single.customerPhone, '9876543210');
      expect(controller.savedOrderNumber.value, 'TA-1001');
      expect(controller.takeAwayHoldOrderId.value, 1001);
      expect(controller.pendingTakeAwayHoldIds, contains(1001));
      expect(controller.lastKitchenOrderItems, hasLength(2));

      expect(
        await controller.prepareTakeAwayOrderForCompletion(staffId: 1),
        isTrue,
      );
      expect(repository.requests, hasLength(1));
      expect(repository.requests.single.printKitchen, isTrue);

      expect(await controller.completeTakeAwayOrder(), isTrue);
      expect(saveRepository.requests.single.holdOrderIds, [1001]);
      expect(controller.pendingTakeAwayHoldIds, isEmpty);
      expect(controller.savedOrderNumber.value, 'TA-FINAL-1001');
      expect(controller.completedTakeAwayOrder.value?.subtotal, 45);
      expect(controller.completedTakeAwayOrder.value?.gst, 2.25);
      expect(controller.completedTakeAwayOrder.value?.discountAmount, 3);
      expect(controller.completedTakeAwayOrder.value?.charge, 1.5);
      expect(controller.completedTakeAwayOrder.value?.total, 47.25);
      final receiptItems = controller.completedTakeAwayReceiptItems;
      expect(receiptItems, hasLength(2));
      expect(receiptItems.first.product.price, 55.56);
      expect(receiptItems.first.total, 25);
      expect(await controller.completeTakeAwayOrder(), isTrue);
      expect(saveRepository.requests, hasLength(1));
      expect(controller.completedTakeAwayOrders, hasLength(1));

      controller.startNewBill();
      expect(controller.takeAwayCustomerName.value, isEmpty);
      expect(controller.takeAwayCustomerPhone.value, isEmpty);
      expect(controller.takeAwayHoldOrderId.value, isNull);
      expect(controller.isTakeAwayOrderCompleted.value, isFalse);
      expect(controller.completedTakeAwayOrders, hasLength(1));
    },
  );

  test('take away close hold sends every product as pending KOT', () async {
    final repository = _FakeTakeAwayHoldRepository();
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
      null,
      null,
      null,
      null,
      TakeAwayHoldUseCase(repository),
    )..selectFlow(PosFlow.takeAway);
    controller.addProduct(
      const Product(id: 4, name: 'Burger', unit: 'kg', price: 100, image: ''),
    );
    controller.addProduct(
      const Product(id: 3, name: 'Tea', unit: 'pcs', price: 20, image: ''),
    );
    controller.setItemAmount(controller.cart.first, 0.45);
    controller.takeAwayCustomerName.value = 'Jenil';
    controller.takeAwayCustomerPhone.value = '0987654321';

    expect(
      await controller.prepareTakeAwayOrderForCompletion(staffId: 1),
      isTrue,
    );

    expect(repository.requests, hasLength(1));
    expect(repository.requests.single.products, hasLength(2));
    expect(repository.requests.single.products[0].productId, 4);
    expect(repository.requests.single.products[0].apiQuantity, '0.45kg');
    expect(repository.requests.single.products[0].isKot, isFalse);
    expect(repository.requests.single.products[1].productId, 3);
    expect(repository.requests.single.products[1].apiQuantity, '1pcs');
    expect(repository.requests.single.products[1].isKot, isFalse);
    expect(controller.lastKitchenOrderItems, isEmpty);
  });

  test(
    'next take away kitchen bill sends only new products and quantity',
    () async {
      final repository = _FakeTakeAwayHoldRepository(secondResponseId: 2002);
      final saveRepository = _FakeTakeAwaySaveOrderRepository();
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
        null,
        null,
        null,
        null,
        TakeAwayHoldUseCase(repository),
        TakeAwaySaveOrderUseCase(saveRepository),
      )..selectFlow(PosFlow.takeAway);
      const burger = Product(
        id: 4,
        name: 'Burger',
        unit: 'pcs',
        price: 100,
        image: '',
      );
      const tea = Product(
        id: 5,
        name: 'Tea',
        unit: 'pcs',
        price: 20,
        image: '',
      );
      const cake = Product(
        id: 6,
        name: 'Cake',
        unit: 'pcs',
        price: 50,
        image: '',
      );
      controller.addProduct(burger);
      controller.addProduct(tea);
      controller.takeAwayCustomerName.value = 'Anu';
      controller.takeAwayCustomerPhone.value = '9876543210';

      expect(controller.canSendTakeAwayKitchenBill, isTrue);
      expect(await controller.saveTakeAwayKitchenBill(staffId: 1), isTrue);
      expect(repository.requests.single.products, hasLength(2));
      expect(controller.hasTakeAwayPendingKitchenItems, isFalse);
      expect(controller.canSendTakeAwayKitchenBill, isFalse);

      controller.confirmKitchenOrderPrinted();
      controller.increment(controller.cart.last);
      controller.addProduct(cake);

      expect(controller.hasTakeAwayPendingKitchenItems, isTrue);
      expect(controller.canSendTakeAwayKitchenBill, isTrue);
      expect(await controller.saveTakeAwayKitchenBill(staffId: 1), isTrue);

      expect(repository.requests, hasLength(2));
      expect(repository.requests.first.holdOrderId, isNull);
      expect(repository.requests.last.holdOrderId, 1001);
      expect(repository.requests.last.toFormFields()['hold_order_id'], 1001);
      expect(controller.takeAwayHoldOrderId.value, 1001);
      expect(controller.takeAwayHoldOrderIds, [1001, 2002]);
      final deltaProducts = repository.requests.last.products;
      expect(deltaProducts, hasLength(2));
      expect(deltaProducts[0].productId, tea.id);
      expect(deltaProducts[0].apiQuantity, '1pcs');
      expect(deltaProducts[1].productId, cake.id);
      expect(deltaProducts[1].apiQuantity, '1pcs');
      expect(controller.lastKitchenOrderItems, hasLength(2));
      expect(controller.hasTakeAwayPendingKitchenItems, isFalse);
      expect(controller.canSendTakeAwayKitchenBill, isFalse);

      expect(await controller.completeTakeAwayOrder(), isTrue);
      expect(saveRepository.requests.single.holdOrderIds, [1001, 2002]);
    },
  );

  test('take away kitchen bill requires customer details', () async {
    final repository = _FakeTakeAwayHoldRepository();
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
      null,
      null,
      null,
      null,
      TakeAwayHoldUseCase(repository),
    );
    controller.addProduct(
      const Product(id: 4, name: 'Burger', unit: 'pcs', price: 100, image: ''),
    );
    controller.setKitchenItemSelected(controller.cart.single, true);

    expect(await controller.saveTakeAwayKitchenBill(staffId: 1), isFalse);
    expect(repository.requests, isEmpty);
    expect(
      controller.takeAwayHoldError.value,
      'Customer name and phone number are required.',
    );
  });

  test(
    'take away kitchen bill rejects an invalid phone before the API',
    () async {
      final repository = _FakeTakeAwayHoldRepository();
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
        null,
        null,
        null,
        null,
        TakeAwayHoldUseCase(repository),
      );
      controller.addProduct(
        const Product(
          id: 4,
          name: 'Burger',
          unit: 'pcs',
          price: 100,
          image: '',
        ),
      );
      controller.setKitchenItemSelected(controller.cart.single, true);
      controller.takeAwayCustomerName.value = 'Anu';
      controller.takeAwayCustomerPhone.value = '12345';

      expect(await controller.saveTakeAwayKitchenBill(staffId: 1), isFalse);
      expect(repository.requests, isEmpty);
      expect(
        controller.takeAwayHoldError.value,
        'Customer phone number must be exactly 10 digits.',
      );
    },
  );

  test(
    'allows new take-away products and quantity after kitchen bill',
    () async {
      final controller = HomeController()..selectFlow(PosFlow.takeAway);
      const burger = Product(
        id: 4,
        name: 'Burger',
        unit: 'pcs',
        price: 100,
        image: '',
      );
      const tea = Product(
        id: 5,
        name: 'Tea',
        unit: 'pcs',
        price: 20,
        image: '',
      );
      controller.addProduct(burger);
      final heldItem = controller.cart.single;
      controller.takeAwayHoldOrderId.value = 1001;

      controller.addProduct(tea);
      controller.increment(heldItem);
      controller.updateItemNotes(heldItem, 'changed');

      expect(controller.cart, hasLength(2));
      expect(heldItem.quantity, 2);
      expect(heldItem.notes, 'changed');
      expect(controller.hasTakeAwayPendingKitchenItems, isTrue);
    },
  );

  test('take-away receipt totals ignore a partial backend response', () {
    final controller = HomeController()..selectFlow(PosFlow.takeAway);
    controller.cart.assignAll([
      CartItem(
        product: const Product(
          id: 1,
          name: 'Cake',
          unit: 'pcs',
          price: 999.89,
          image: '',
        ),
      ),
      CartItem(
        product: const Product(
          id: 2,
          name: 'Juice',
          unit: 'pcs',
          price: 200,
          image: '',
        ),
      ),
    ]);
    controller.backendSubtotal.value = 190.48;
    controller.backendGst.value = 9.52;
    controller.backendTotal.value = 200;

    expect(controller.subtotal, 190.48);
    expect(controller.cartItemsSubtotal, closeTo(1199.89, 0.000001));
    expect(controller.cartItemsTax, 0);
    expect(controller.cartItemsTotal, closeTo(1199.89, 0.000001));
  });

  testWidgets('take away billing shows kitchen bill and take away actions', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorageService.initialize();
    Get.put(
      PrinterManager(
        LocalPrinterRepository(storage),
        ReceiptPrinterService(),
        KitchenPrinter(),
      ),
    );
    final repository = _FakeOrderRepository();
    final controller = HomeController(null, SaveOrderUseCase(repository))
      ..onInit()
      ..selectFlow(PosFlow.takeAway);
    controller.cart.assignAll([
      CartItem(product: controller.products[0], quantity: 2),
      CartItem(product: controller.products[2]),
      CartItem(product: controller.products[4]),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BillSummaryPanel(controller: controller)),
      ),
    );
    await tester.pump();

    expect(find.widgetWithText(FilledButton, 'Kitchen Bill'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Take Away'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Pending'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Completed'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Customer Details'),
      findsOneWidget,
    );
    expect(find.byType(Checkbox), findsNothing);
    expect(controller.kitchenSelectedItems, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, 'Kitchen Bill'));
    await tester.pumpAndSettle();
    expect(find.text('Customer details'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump();
    expect(find.text('Customer name is required.'), findsOneWidget);
    expect(find.text('Phone number is required.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    controller.takeAwayCustomerName.value = 'Anu';
    controller.takeAwayCustomerPhone.value = '12345';
    await tester.pump();
    expect(
      find.widgetWithText(OutlinedButton, 'Edit Customer Details'),
      findsOneWidget,
    );
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Edit Customer Details'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump();
    expect(
      find.text('Phone number must be exactly 10 digits.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Demo'), findsNothing);
    expect(repository.requests, isEmpty);
    controller.onClose();
  });
}

class _FakeOrderRepository implements OrderRepository {
  final requests = <SaveOrderRequest>[];

  @override
  Future<SaveOrderResponse> saveOrder(SaveOrderRequest request) async {
    requests.add(request);
    return const SaveOrderResponse(status: true);
  }
}

class _FakeTakeAwayHoldRepository implements TakeAwayHoldRepository {
  _FakeTakeAwayHoldRepository({
    this.secondResponseId,
    this.includeProductDetails = false,
  });

  final requests = <TakeAwayHoldRequest>[];
  final int? secondResponseId;
  final bool includeProductDetails;

  @override
  Future<TakeAwayHoldResponse> holdTakeAway(TakeAwayHoldRequest request) async {
    requests.add(request);
    final responseId = requests.length > 1 && secondResponseId != null
        ? secondResponseId!
        : 1001;
    return TakeAwayHoldResponse(
      status: true,
      message: 'Take-away order held',
      data: TakeAwayHoldData(
        isProcessing: true,
        order: TakeAwayHoldOrder(
          id: responseId,
          orderId: 'TA-$responseId',
          subtotal: 45,
          gst: 2.25,
          total: 47.25,
          products: includeProductDetails
              ? const <TakeAwayHoldProduct>[
                  TakeAwayHoldProduct(
                    id: 937,
                    orderId: 1001,
                    productId: 4,
                    quantity: 1,
                  ),
                ]
              : const <TakeAwayHoldProduct>[],
        ),
      ),
    );
  }
}

class _FakeTakeAwayRemoveProductRepository
    implements TakeAwayRemoveProductRepository {
  final requests = <RemoveKotProductRequest>[];

  @override
  Future<RemoveKotProductResponse> removeTakeAwayProduct(
    RemoveKotProductRequest request,
  ) async {
    requests.add(request);
    return const RemoveKotProductResponse(
      status: true,
      message: 'Take-away product removed',
    );
  }
}

class _FakeTakeAwayChangeQuantityRepository
    implements TakeAwayChangeQuantityRepository {
  final requests = <TakeAwayChangeQuantityRequest>[];

  @override
  Future<TakeAwayChangeQuantityResponse> changeTakeAwayQuantity(
    TakeAwayChangeQuantityRequest request,
  ) async {
    requests.add(request);
    return const RemoveKotQuantityResponse(
      status: true,
      message: 'Quantity changed',
    );
  }
}

class _FakeTakeAwaySaveOrderRepository implements TakeAwaySaveOrderRepository {
  final requests = <TakeAwaySaveOrderRequest>[];

  @override
  Future<TakeAwaySaveOrderResponse> saveTakeAwayOrder(
    TakeAwaySaveOrderRequest request,
  ) async {
    requests.add(request);
    return const TakeAwaySaveOrderResponse(
      status: true,
      message: 'Take-away order saved',
      order: SavedOrder(
        id: 2001,
        orderId: 'TA-FINAL-1001',
        subtotal: 45,
        gst: 2.25,
        discountAmount: 3,
        charge: 1.5,
        total: 47.25,
        paymentMode: 'cash',
        products: <SavedOrderProduct>[
          SavedOrderProduct(
            id: 10,
            productId: 4,
            productName: 'Burger',
            price: 55.56,
            quantity: 1,
            unitValue: 0.45,
            unit: 'kg',
            rowTotal: 25,
          ),
          SavedOrderProduct(
            id: 11,
            productId: 5,
            productName: 'Tea',
            price: 20,
            quantity: 1,
            unitValue: 1,
            unit: 'pcs',
            rowTotal: 20,
          ),
        ],
      ),
    );
  }
}

class _FakeTakeAwaySaveOrderWithoutOrderRepository
    implements TakeAwaySaveOrderRepository {
  @override
  Future<TakeAwaySaveOrderResponse> saveTakeAwayOrder(
    TakeAwaySaveOrderRequest request,
  ) async {
    return const TakeAwaySaveOrderResponse(
      status: true,
      message: 'Take-away order saved',
    );
  }
}

class _FakeTakeAwayProcessingRepository
    implements TakeAwayProcessingRepository {
  final holdOrderIds = <int>[];

  @override
  Future<TakeAwayProcessingResponse> getProcessingTakeAway([
    int? holdOrderId,
  ]) async {
    if (holdOrderId != null) holdOrderIds.add(holdOrderId);
    final id = holdOrderId ?? 97;
    return TakeAwayProcessingResponse(
      status: true,
      orders: [
        TakeAwayProcessingOrder(
          id: id,
          holdOrderId: id,
          orderId: 'TA-$id',
          customerName: 'Anu',
          customerPhone: '9876543210',
          status: 'processing',
          products: holdOrderId == null
              ? const []
              : const [
                  TakeAwayProcessingProduct(
                    productId: 4,
                    productName: 'Snack',
                    quantity: '1',
                    unit: 'pcs',
                    price: 50,
                    rowTotal: 50,
                  ),
                ],
        ),
      ],
    );
  }
}

class _FakeTakeAwayCompletedViewRepository
    implements TakeAwayCompletedViewRepository {
  final completedOrderIds = <int>[];
  final holdOrderIds = <int>[];

  @override
  Future<TakeAwayProcessingResponse> getCompletedTakeAwayView(
    int completedOrderId,
    int holdOrderId,
  ) async {
    completedOrderIds.add(completedOrderId);
    holdOrderIds.add(holdOrderId);
    return TakeAwayProcessingResponse(
      status: true,
      orders: [
        TakeAwayProcessingOrder(
          id: completedOrderId,
          holdOrderId: holdOrderId,
          orderId: 'TA-$completedOrderId',
          status: 'completed',
        ),
      ],
    );
  }
}

class _FakeTakeAwayCompletedRepository implements TakeAwayCompletedRepository {
  final holdOrderIds = <int?>[];

  @override
  Future<TakeAwayProcessingResponse> getCompletedTakeAway([
    int? holdOrderId,
  ]) async {
    holdOrderIds.add(holdOrderId);
    if (holdOrderId == null) {
      return const TakeAwayProcessingResponse(status: true);
    }
    return TakeAwayProcessingResponse(
      status: true,
      orders: [
        TakeAwayProcessingOrder(
          id: holdOrderId,
          orderId: 'TA-$holdOrderId',
          status: 'completed',
        ),
      ],
    );
  }
}
