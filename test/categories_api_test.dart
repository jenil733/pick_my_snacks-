import 'package:pick_my_snacks/src/presentation/view/homescreen/mobile/mobile_products_screen.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/cart_controller.dart';
import 'dart:async';
import 'package:pick_my_snacks/src/domain/usecase/get_category_products_usecase.dart';
import 'package:pick_my_snacks/src/data/model/get_product.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/category_billing_panel.dart';
import 'package:get/get.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_snacks/src/data/model/get_category.dart';
import 'package:pick_my_snacks/src/domain/repository/category_repository.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_categories_usecase.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';

class FakeCategories implements CategoryRepository {
  @override
  Future<GetProductResponse> getCategoryProducts(int categoryId) async =>
      const GetProductResponse(success: true, data: []);
  bool fail = false;
  List<BillingCategory> data = [const BillingCategory(id: 18, name: 'Cookies')];
  @override
  Future<CategoryResponse> getCategories() async {
    if (fail) throw Exception('offline');
    return CategoryResponse(success: true, data: data);
  }
}

class PendingCategoryProducts extends FakeCategories {
  final requests = <int, Completer<GetProductResponse>>{};
  @override
  Future<GetProductResponse> getCategoryProducts(int categoryId) {
    final request = Completer<GetProductResponse>();
    requests[categoryId] = request;
    return request.future;
  }
}

void main() {
  testWidgets(
    'mobile opens with searchable cards and returns from billing products',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      Get.put(CartController());
      final controller = HomeController();
      controller.flow.value = PosFlow.categoryBilling;
      controller.products.assignAll([
        const Product(
          id: 1,
          name: 'Tea product',
          category: 'Tea',
          price: 15,
          image: '',
          unit: 'pcs',
        ),
      ]);
      controller.billingCategories.assignAll([
        const BillingCategory(id: 21, name: 'Tea'),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileProductsScreen(
              controller: controller,
              onOpenBill: () {},
            ),
          ),
        ),
      );
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Tea product'), findsNothing);
      await tester.enterText(find.byType(TextFormField), '21');
      await tester.pump();
      expect(find.text('Tea'), findsOneWidget);
      await tester.tap(find.text('Tea'));
      await tester.pumpAndSettle();
      expect(find.text('Tea product'), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
      await tester.tap(find.byTooltip('Back to categories'));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Tea product'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      Get.reset();
    },
  );

  test(
    'category requests use IDs, ignore stale results, and retry failures',
    () async {
      final repository = PendingCategoryProducts();
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
        null,
        null,
        null,
        null,
        GetCategoriesUseCase(repository),
        GetCategoryProductsUseCase(repository),
      );
      controller.billingCategories.assignAll([
        const BillingCategory(id: 21, name: 'Tea'),
        const BillingCategory(id: 18, name: 'Cookies'),
      ]);
      controller.selectCategory('Tea');
      expect(controller.selectedCategoryId.value, 21);
      expect(controller.isLoadingCategoryProducts.value, isTrue);
      controller.selectCategory('Cookies');
      repository.requests[18]!.complete(
        GetProductResponse.fromJson({
          'success': true,
          'data': [
            {
              'id': 2,
              'product_name': 'Cookie',
              'kitchen_category_id': 18,
              'price': '20.00',
              'is_active': 1,
            },
          ],
        }),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.categoryFilteredProducts.single.name, 'Cookie');
      expect(controller.categoryFilteredProducts.single.categoryId, 18);
      repository.requests[21]!.complete(
        const GetProductResponse(success: true, data: []),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.categoryFilteredProducts.single.name, 'Cookie');
      controller.searchQuery.value = 'missing';
      expect(controller.categoryFilteredProducts, isEmpty);
      controller.searchQuery.value = '';
      final failed = controller.getCategoryProducts();
      repository.requests[18]!.completeError(Exception('offline'));
      await failed;
      expect(controller.categoryProductsError.value, isNotNull);
      expect(controller.categoryFilteredProducts, isEmpty);
      expect(controller.isLoadingCategoryProducts.value, isFalse);
      final retried = controller.getCategoryProducts();
      repository.requests[18]!.complete(
        const GetProductResponse(success: true, data: []),
      );
      await retried;
      expect(controller.categoryProductsError.value, isNull);
      expect(controller.categoryFilteredProducts, isEmpty);
    },
  );

  testWidgets(
    'category panel rebuilds through loading, error, and loaded states',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
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
        null,
        null,
        null,
        null,
        GetCategoriesUseCase(FakeCategories()),
      );
      controller.isLoadingCategories.value = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 500,
              child: CategoryListPanel(controller: controller),
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);

      controller.isLoadingCategories.value = false;
      controller.categoryError.value = 'Unable to load categories.';
      await tester.pump();
      expect(find.text('Retry'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Cookies'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Cookies'));
      await tester.pump();
      expect(controller.selectedCategory.value, 'Cookies');
      expect(tester.takeException(), isNull);
    },
  );

  test('parses billing API category fields', () {
    final response = CategoryResponse.fromJson({
      'success': true,
      'data': [
        {'id': 18, 'category': 'Cookies', 'image': null},
      ],
    });
    expect(response.success, isTrue);
    expect(response.data.single.id, 18);
    expect(response.data.single.name, 'Cookies');
    expect(response.data.single.image, isNull);
  });

  test(
    'loads API categories, filters by ID, and recovers after failure',
    () async {
      final repository = FakeCategories();
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
        null,
        null,
        null,
        null,
        GetCategoriesUseCase(repository),
      );
      controller.flow.value = PosFlow.categoryBilling;
      controller.products.assignAll([
        const Product(
          id: 1,
          name: 'Cookie',
          unit: 'pc',
          price: 10,
          image: '',
          categoryId: 18,
        ),
        const Product(
          id: 2,
          name: 'Other',
          unit: 'pc',
          price: 20,
          image: '',
          category: 'Cookies',
          categoryId: 19,
        ),
      ]);
      await controller.getCategories();
      expect(controller.categories, ['Cookies']);
      expect(controller.selectedCategory.value, isNull);
      expect(controller.categoryFilteredProducts, isEmpty);
      controller.categorySearchQuery.value = '18';
      expect(controller.filteredCategories, ['Cookies']);
      controller.categorySearchQuery.value = 'COOK';
      expect(controller.filteredCategories, ['Cookies']);
      controller.categorySearchQuery.value = 'missing';
      expect(controller.filteredCategories, isEmpty);
      controller.selectCategory('Cookies');
      expect(controller.categoryFilteredProducts.single.id, 1);
      expect(controller.getCategoryProductCount('Cookies'), 1);
      repository.fail = true;
      await controller.getCategories();
      expect(controller.categoryError.value, isNotNull);
      expect(controller.isLoadingCategories.value, isFalse);
      expect(controller.categories, ['Cookies']);
      repository.fail = false;
      repository.data = [];
      await controller.getCategories();
      expect(controller.categoryError.value, isNull);
      expect(controller.categories, isEmpty);
      expect(controller.selectedCategory.value, isNull);
    },
  );
}
