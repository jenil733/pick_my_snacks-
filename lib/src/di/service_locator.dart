import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/core/services/local_storage.dart';
import 'package:pick_my_snacks/src/data/repository/product_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/delete_held_bill_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/resume_order_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/get_hold_orders_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/login_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/hold_order_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/order_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/staff_repository_impl.dart';
import 'package:pick_my_snacks/src/domain/repository/delete_held_bill_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/get_hold_orders_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/hold_order_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/login_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/order_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/product_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/resume_order_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/staff_repository.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_staff_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/delete_held_bill_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_hold_orders_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/hold_order_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/login_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_products_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_order_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/resume_order_usecase.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/login/login_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/staff/staff_controller.dart';

Future<void> setupServiceLocator() async {
  if (!Get.isRegistered<LocalStorageService>()) {
    final storage = await LocalStorageService.initialize();
    Get.put<LocalStorageService>(storage, permanent: true);
  }

  if (!Get.isRegistered<ApiService>()) {
    Get.put<ApiService>(
      ApiService(storage: Get.find<LocalStorageService>()),
      permanent: true,
    );
  }

  if (!Get.isRegistered<ProductRepository>()) {
    Get.lazyPut<ProductRepository>(
      () => ProductRepositoryImpl(Get.find<ApiService>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<LoginRepository>()) {
    Get.lazyPut<LoginRepository>(
      () => LoginRepositoryImpl(
        Get.find<ApiService>(),
        Get.find<LocalStorageService>(),
      ),
      fenix: true,
    );
  }

  if (!Get.isRegistered<StaffRepository>()) {
    Get.lazyPut<StaffRepository>(
      () => StaffRepositoryImpl(Get.find<ApiService>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<OrderRepository>()) {
    Get.lazyPut<OrderRepository>(
      () => OrderRepositoryImpl(Get.find<ApiService>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<HoldOrderRepository>()) {
    Get.lazyPut<HoldOrderRepository>(
      () => HoldOrderRepositoryImpl(Get.find<ApiService>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<GetHoldOrdersRepository>()) {
    Get.lazyPut<GetHoldOrdersRepository>(
      () => GetHoldOrdersRepositoryImpl(Get.find<ApiService>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<ResumeOrderRepository>()) {
    Get.lazyPut<ResumeOrderRepository>(
      () => ResumeOrderRepositoryImpl(Get.find<ApiService>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<DeleteHeldBillRepository>()) {
    Get.lazyPut<DeleteHeldBillRepository>(
      () => DeleteHeldBillRepositoryImpl(Get.find<ApiService>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<LoginUseCase>()) {
    Get.lazyPut<LoginUseCase>(
      () => LoginUseCase(Get.find<LoginRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<LoginController>()) {
    Get.lazyPut<LoginController>(
      () => LoginController(Get.find<LoginUseCase>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<GetProductsUseCase>()) {
    Get.lazyPut<GetProductsUseCase>(
      () => GetProductsUseCase(Get.find<ProductRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<GetStaffUseCase>()) {
    Get.lazyPut<GetStaffUseCase>(
      () => GetStaffUseCase(Get.find<StaffRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<SaveOrderUseCase>()) {
    Get.lazyPut<SaveOrderUseCase>(
      () => SaveOrderUseCase(Get.find<OrderRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<HoldOrderUseCase>()) {
    Get.lazyPut<HoldOrderUseCase>(
      () => HoldOrderUseCase(Get.find<HoldOrderRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<GetHoldOrdersUseCase>()) {
    Get.lazyPut<GetHoldOrdersUseCase>(
      () => GetHoldOrdersUseCase(Get.find<GetHoldOrdersRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<ResumeOrderUseCase>()) {
    Get.lazyPut<ResumeOrderUseCase>(
      () => ResumeOrderUseCase(Get.find<ResumeOrderRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<DeleteHeldBillUseCase>()) {
    Get.lazyPut<DeleteHeldBillUseCase>(
      () => DeleteHeldBillUseCase(Get.find<DeleteHeldBillRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<HomeController>()) {
    Get.lazyPut<HomeController>(
      () => HomeController(
        Get.find<GetProductsUseCase>(),
        Get.find<SaveOrderUseCase>(),
        Get.find<HoldOrderUseCase>(),
        Get.find<GetHoldOrdersUseCase>(),
        Get.find<ResumeOrderUseCase>(),
        Get.find<DeleteHeldBillUseCase>(),
      ),
      fenix: true,
    );
  }

  if (!Get.isRegistered<StaffController>()) {
    Get.lazyPut<StaffController>(
      () => StaffController(Get.find<GetStaffUseCase>()),
      fenix: true,
    );
  }
}

T locate<T>() => Get.find<T>();
