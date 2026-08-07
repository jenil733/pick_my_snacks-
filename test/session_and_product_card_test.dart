import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pick_my_snacks/src/core/services/local_storage.dart';
import 'package:pick_my_snacks/src/data/model/get_staff.dart';
import 'package:pick_my_snacks/src/domain/repository/staff_repository.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_staff_usecase.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/staff/staff_controller.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/products_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/staff_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(Get.reset);

  test('opens home when a bearer token is saved', () async {
    SharedPreferences.setMockInitialValues({
      LocalStorageService.authTokenKey: 'saved-token',
    });
    final storage = await LocalStorageService.initialize();

    expect(storage.hasAuthenticatedSession, isTrue);

    await storage.remove(LocalStorageService.authTokenKey);
    expect(storage.hasAuthenticatedSession, isFalse);
  });

  test('restores and updates the selected staff ID', () async {
    SharedPreferences.setMockInitialValues({
      LocalStorageService.selectedStaffIdKey: 7,
    });
    final storage = await LocalStorageService.initialize();
    final controller = StaffController(
      GetStaffUseCase(_FakeStaffRepository()),
      storage,
    );

    await controller.getStaff();
    expect(controller.selectedStaff.value?.name, 'Asha');

    await controller.selectStaff(
      const StaffData(id: 9, name: 'Vikram', designation: 'Cashier'),
    );
    expect(storage.getInt(LocalStorageService.selectedStaffIdKey), 9);
  });

  testWidgets('shows an available product code on the product card', (
    tester,
  ) async {
    final controller = HomeController();
    controller.products.assignAll(const [
      Product(
        id: 1,
        productId: 'SNK-0042',
        name: 'Test Snack',
        unit: '50g',
        price: 25,
        image: '',
      ),
    ]);

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(body: ProductsPanel(controller: controller)),
      ),
    );

    expect(find.text('Code: SNK-0042'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('enables the staff dropdown after staff finishes loading', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorageService.initialize();
    final repository = _DelayedStaffRepository();
    Get.put(
      StaffController(GetStaffUseCase(repository), storage),
      permanent: true,
    );

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: StaffMenu()),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Staff'));
    await tester.pumpAndSettle();

    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Vikram'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeStaffRepository implements StaffRepository {
  @override
  Future<StaffListResponse> getStaff() async {
    return const StaffListResponse(
      status: true,
      data: [
        StaffData(id: 7, name: 'Asha', designation: 'Cashier'),
        StaffData(id: 9, name: 'Vikram', designation: 'Cashier'),
      ],
    );
  }
}

class _DelayedStaffRepository implements StaffRepository {
  final _completer = Completer<StaffListResponse>();

  void complete() => _completer.complete(
    const StaffListResponse(
      status: true,
      data: [
        StaffData(id: 7, name: 'Asha', designation: 'Cashier'),
        StaffData(id: 9, name: 'Vikram', designation: 'Cashier'),
      ],
    ),
  );

  @override
  Future<StaffListResponse> getStaff() => _completer.future;
}
