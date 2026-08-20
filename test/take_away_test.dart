import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide FormData, Response;
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/core/services/local_storage.dart';
import 'package:pick_my_snacks/src/data/model/get_staff.dart';
import 'package:pick_my_snacks/src/data/model/save_order.dart';
import 'package:pick_my_snacks/src/data/model/take_away_hold.dart';
import 'package:pick_my_snacks/src/data/model/take_away_processing.dart';
import 'package:pick_my_snacks/src/data/model/take_away_save_order.dart';
import 'package:pick_my_snacks/src/data/repository/take_away_processing_repository_impl.dart';
import 'package:pick_my_snacks/src/domain/repository/order_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_completed_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_completed_view_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_hold_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_processing_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_save_order_repository.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_take_away_completed_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_take_away_completed_view_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_take_away_processing_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_order_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/take_away_hold_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/take_away_save_order_usecase.dart';
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
  tearDown(Get.reset);

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
      'charge': '',
      'payment_mode': 'cash',
      'status': '',
      'products[0][product_id]': 4,
      'products[0][qty]': '0.45kg',
      'products[0][note]': 'extra salt',
      'products[0][is_kot]': 0,
      'products[1][product_id]': 5,
      'products[1][qty]': '1pcs',
      'products[1][note]': '',
      'products[1][is_kot]': 1,
      'discount_type': '',
      'discount_value': '',
    });
  });

  test('builds the take_away_save_order multipart fields', () {
    const request = TakeAwaySaveOrderRequest(holdOrderId: 159);

    expect(request.toFormFields(), {'hold_order_id': 159});
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
    expect(saveRepository.requests.single.holdOrderId, 97);
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
    expect(repository.requests.single.holdOrderId, 162);
    expect(controller.takeAwayProcessingOrders, isEmpty);
    expect(controller.completedTakeAwayOrders.single.customerName, 'test');
  });

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
      controller.setKitchenItemSelected(controller.cart.first, true);
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
      expect(repository.requests.single.products[0].isKot, isTrue);
      expect(repository.requests.single.products[1].productId, 5);
      expect(repository.requests.single.products[1].apiQuantity, '1pcs');
      expect(repository.requests.single.products[1].isKot, isFalse);
      expect(repository.requests.single.customerName, 'Anu');
      expect(repository.requests.single.customerPhone, '9876543210');
      expect(controller.savedOrderNumber.value, 'TA-1001');
      expect(controller.takeAwayHoldOrderId.value, 1001);
      expect(controller.pendingTakeAwayHoldIds, contains(1001));
      expect(controller.lastKitchenOrderItems.single.product.id, 4);

      expect(await controller.saveTakeAwayKitchenBill(staffId: 1), isFalse);
      expect(repository.requests, hasLength(1));
      expect(
        controller.takeAwayHoldError.value,
        contains('already in Pending'),
      );

      expect(await controller.completeTakeAwayOrder(), isTrue);
      expect(saveRepository.requests.single.holdOrderId, 1001);
      expect(controller.pendingTakeAwayHoldIds, isEmpty);
      expect(controller.savedOrderNumber.value, 'TA-FINAL-1001');
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

  test(
    'take away close hold sends all products with individual kitchen flags',
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
      )..selectFlow(PosFlow.takeAway);
      controller.addProduct(
        const Product(id: 4, name: 'Burger', unit: 'kg', price: 100, image: ''),
      );
      controller.addProduct(
        const Product(id: 3, name: 'Tea', unit: 'pcs', price: 20, image: ''),
      );
      controller.setItemAmount(controller.cart.first, 0.45);
      controller.setKitchenItemSelected(controller.cart.last, true);
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
      expect(repository.requests.single.products[1].isKot, isTrue);
      expect(controller.lastKitchenOrderItems.single.product.id, 3);
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
    expect(find.byType(Checkbox), findsWidgets);
    expect(controller.kitchenSelectedItems, isEmpty);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(controller.kitchenSelectedItems, contains(controller.cart.first));
    expect(controller.kitchenSelectedItems, hasLength(1));

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
  final requests = <TakeAwayHoldRequest>[];

  @override
  Future<TakeAwayHoldResponse> holdTakeAway(TakeAwayHoldRequest request) async {
    requests.add(request);
    return const TakeAwayHoldResponse(
      status: true,
      message: 'Take-away order held',
      data: SaveOrderData(
        order: SavedOrder(
          id: 1001,
          orderId: 'TA-1001',
          subtotal: 45,
          gst: 2.25,
          total: 47.25,
        ),
      ),
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
        total: 47.25,
      ),
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
