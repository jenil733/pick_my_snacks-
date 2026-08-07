import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pick_my_snacks/main.dart';
import 'package:pick_my_snacks/src/core/utils/navigation/approutes.dart';
import 'package:pick_my_snacks/src/data/model/get_product.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(Get.reset);

  test('parses the low-stock API response', () {
    final response = LowStockProductsResponse.fromJson({
      'status': true,
      'message': 'Low stock products fetched successfully.',
      'count': 1,
      'data': [
        {
          'id': 6,
          'product_id': '1009',
          'product_name': 'Test product',
          'stock': 4,
          'unit': 'kg',
          'price': '45.00',
        },
      ],
    });

    expect(response.status, isTrue);
    expect(response.count, 1);
    expect(response.data, hasLength(1));
    expect(response.data!.single.productName, 'Test product');
    expect(response.data!.single.stock, 4);
  });

  test('parses the out-of-stock API response', () {
    final response = OutOfStockProductsResponse.fromJson({
      'status': true,
      'message': 'Out of stock products fetched successfully.',
      'count': 0,
      'data': <Map<String, dynamic>>[],
    });

    expect(response.status, isTrue);
    expect(response.count, 0);
    expect(response.data, isEmpty);
  });

  test('parses the notification-count API response', () {
    final response = NotificationCountResponse.fromJson({
      'status': true,
      'message': 'Kitchen notification fetched successfully.',
      'data': {'notification_count': 2},
    });

    expect(response.status, isTrue);
    expect(response.count, 2);
  });

  testWidgets('opens counted low-stock and out-of-stock tabs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const MyApp(initialRoute: AppRoutes.homescreen));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull, reason: 'home screen overflowed');

    await tester.tap(find.byTooltip('Stock notifications'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'low-stock tab overflowed');

    expect(find.text('Stock Notifications'), findsOneWidget);
    expect(find.text('Low Stock'), findsOneWidget);
    expect(find.text('Out of Stock'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Bisleri Water Bottle'), findsOneWidget);

    await tester.tap(find.text('Out of Stock'));
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
      reason: 'out-of-stock tab overflowed',
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.text('Coca Cola'), findsOneWidget);
  });
}
