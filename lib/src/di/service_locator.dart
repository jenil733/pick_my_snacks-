import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/core/services/fcm_token_service.dart';
import 'package:pick_my_snacks/src/core/services/local_storage.dart';
import 'package:pick_my_snacks/src/core/utils/navigation/approutes.dart';
import 'package:pick_my_snacks/src/data/repository/product_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/delete_held_bill_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/resume_order_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/remove_kot_product_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/remove_kot_quantity_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/get_hold_orders_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/login_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/hold_order_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/kot_order_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/kot_save_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/order_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/staff_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/table_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/table_status_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/take_away_hold_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/take_away_completed_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/take_away_completed_view_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/take_away_processing_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/take_away_save_order_repository_impl.dart';
import 'package:pick_my_snacks/src/data/repository/processing_order_repository_impl.dart';
import 'package:pick_my_snacks/src/domain/repository/delete_held_bill_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/get_hold_orders_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/hold_order_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/login_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_order_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_save_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/order_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/product_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/resume_order_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/remove_kot_product_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/remove_kot_quantity_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/staff_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/table_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/table_status_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_hold_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_completed_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_completed_view_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_processing_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_save_order_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/processing_order_repository.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_staff_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_tables_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_take_away_completed_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_take_away_completed_view_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_table_status_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_take_away_processing_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_processing_order_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/delete_held_bill_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_hold_orders_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/hold_order_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/login_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_products_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_low_stock_products_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_out_of_stock_products_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_notification_count_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_kot_order_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_kot_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_order_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/take_away_hold_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/take_away_save_order_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/resume_order_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/remove_kot_product_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/remove_kot_quantity_usecase.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/login/login_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/staff/staff_controller.dart';
import 'package:pick_my_snacks/src/printing/kitchen_printer.dart';
import 'package:pick_my_snacks/src/printing/printer_manager.dart';
import 'package:pick_my_snacks/src/printing/printer_repository.dart';
import 'package:pick_my_snacks/src/services/receipt_printer_service.dart';

Future<String> setupServiceLocator() async {
  late final LocalStorageService storage;
  if (!Get.isRegistered<LocalStorageService>()) {
    storage = await LocalStorageService.initialize();
    Get.put<LocalStorageService>(storage, permanent: true);
  } else {
    storage = Get.find<LocalStorageService>();
  }

  if (!Get.isRegistered<ApiService>()) {
    Get.put<ApiService>(
      ApiService(storage: Get.find<LocalStorageService>()),
      permanent: true,
    );
  }

  if (!Get.isRegistered<FcmTokenService>()) {
    Get.put<FcmTokenService>(
      FcmTokenService(Get.find<ApiService>()),
      permanent: true,
    );
  }

  if (!Get.isRegistered<PrinterRepository>()) {
    Get.put<PrinterRepository>(
      LocalPrinterRepository(Get.find<LocalStorageService>()),
      permanent: true,
    );
  }

  if (!Get.isRegistered<ReceiptPrinterService>()) {
    Get.put<ReceiptPrinterService>(ReceiptPrinterService(), permanent: true);
  }

  if (!Get.isRegistered<KitchenPrinter>()) {
    Get.put<KitchenPrinter>(KitchenPrinter(), permanent: true);
  }

  if (!Get.isRegistered<PrinterManager>()) {
    Get.put<PrinterManager>(
      PrinterManager(
        Get.find<PrinterRepository>(),
        Get.find<ReceiptPrinterService>(),
        Get.find<KitchenPrinter>(),
      ),
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
        Get.find<FcmTokenService>(),
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

  if (!Get.isRegistered<TableRepository>()) {
    Get.lazyPut<TableRepository>(
      () => TableRepositoryImpl(Get.find<ApiService>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<TableStatusRepository>()) {
    Get.lazyPut<TableStatusRepository>(
      () => TableStatusRepositoryImpl(Get.find<ApiService>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<ProcessingOrderRepository>()) {
    Get.lazyPut<ProcessingOrderRepository>(
      () => ProcessingOrderRepositoryImpl(Get.find<ApiService>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<OrderRepository>()) {
    Get.lazyPut<OrderRepository>(
      () => OrderRepositoryImpl(Get.find<ApiService>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<KotOrderRepository>()) {
    Get.lazyPut<KotOrderRepository>(
      () => KotOrderRepositoryImpl(Get.find<ApiService>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<KotSaveRepository>()) {
    Get.lazyPut<KotSaveRepository>(
      () => KotSaveRepositoryImpl(Get.find<ApiService>()),
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

  if (!Get.isRegistered<RemoveKotProductRepository>()) {
    Get.lazyPut<RemoveKotProductRepository>(
      () => RemoveKotProductRepositoryImpl(Get.find<ApiService>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<RemoveKotQuantityRepository>()) {
    Get.lazyPut<RemoveKotQuantityRepository>(
      () => RemoveKotQuantityRepositoryImpl(Get.find<ApiService>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<TakeAwayHoldRepository>()) {
    Get.lazyPut<TakeAwayHoldRepository>(
      () => TakeAwayHoldRepositoryImpl(Get.find<ApiService>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<TakeAwaySaveOrderRepository>()) {
    Get.lazyPut<TakeAwaySaveOrderRepository>(
      () => TakeAwaySaveOrderRepositoryImpl(Get.find<ApiService>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<TakeAwayProcessingRepository>()) {
    Get.lazyPut<TakeAwayProcessingRepository>(
      () => TakeAwayProcessingRepositoryImpl(Get.find<ApiService>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<TakeAwayCompletedRepository>()) {
    Get.lazyPut<TakeAwayCompletedRepository>(
      () => TakeAwayCompletedRepositoryImpl(Get.find<ApiService>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<TakeAwayCompletedViewRepository>()) {
    Get.lazyPut<TakeAwayCompletedViewRepository>(
      () => TakeAwayCompletedViewRepositoryImpl(Get.find<ApiService>()),
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

  if (!Get.isRegistered<GetLowStockProductsUseCase>()) {
    Get.lazyPut<GetLowStockProductsUseCase>(
      () => GetLowStockProductsUseCase(Get.find<ProductRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<GetOutOfStockProductsUseCase>()) {
    Get.lazyPut<GetOutOfStockProductsUseCase>(
      () => GetOutOfStockProductsUseCase(Get.find<ProductRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<GetNotificationCountUseCase>()) {
    Get.lazyPut<GetNotificationCountUseCase>(
      () => GetNotificationCountUseCase(Get.find<ProductRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<GetStaffUseCase>()) {
    Get.lazyPut<GetStaffUseCase>(
      () => GetStaffUseCase(Get.find<StaffRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<GetTablesUseCase>()) {
    Get.lazyPut<GetTablesUseCase>(
      () => GetTablesUseCase(Get.find<TableRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<GetTableStatusUseCase>()) {
    Get.lazyPut<GetTableStatusUseCase>(
      () => GetTableStatusUseCase(Get.find<TableStatusRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<GetProcessingOrderUseCase>()) {
    Get.lazyPut<GetProcessingOrderUseCase>(
      () => GetProcessingOrderUseCase(Get.find<ProcessingOrderRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<SaveOrderUseCase>()) {
    Get.lazyPut<SaveOrderUseCase>(
      () => SaveOrderUseCase(Get.find<OrderRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<SaveKotOrderUseCase>()) {
    Get.lazyPut<SaveKotOrderUseCase>(
      () => SaveKotOrderUseCase(Get.find<KotOrderRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<SaveKotUseCase>()) {
    Get.lazyPut<SaveKotUseCase>(
      () => SaveKotUseCase(Get.find<KotSaveRepository>()),
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

  if (!Get.isRegistered<RemoveKotProductUseCase>()) {
    Get.lazyPut<RemoveKotProductUseCase>(
      () => RemoveKotProductUseCase(Get.find<RemoveKotProductRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<RemoveKotQuantityUseCase>()) {
    Get.lazyPut<RemoveKotQuantityUseCase>(
      () => RemoveKotQuantityUseCase(Get.find<RemoveKotQuantityRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<TakeAwayHoldUseCase>()) {
    Get.lazyPut<TakeAwayHoldUseCase>(
      () => TakeAwayHoldUseCase(Get.find<TakeAwayHoldRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<TakeAwaySaveOrderUseCase>()) {
    Get.lazyPut<TakeAwaySaveOrderUseCase>(
      () => TakeAwaySaveOrderUseCase(Get.find<TakeAwaySaveOrderRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<GetTakeAwayProcessingUseCase>()) {
    Get.lazyPut<GetTakeAwayProcessingUseCase>(
      () => GetTakeAwayProcessingUseCase(
        Get.find<TakeAwayProcessingRepository>(),
      ),
      fenix: true,
    );
  }

  if (!Get.isRegistered<GetTakeAwayCompletedUseCase>()) {
    Get.lazyPut<GetTakeAwayCompletedUseCase>(
      () =>
          GetTakeAwayCompletedUseCase(Get.find<TakeAwayCompletedRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<GetTakeAwayCompletedViewUseCase>()) {
    Get.lazyPut<GetTakeAwayCompletedViewUseCase>(
      () => GetTakeAwayCompletedViewUseCase(
        Get.find<TakeAwayCompletedViewRepository>(),
      ),
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
        Get.find<GetTablesUseCase>(),
        Get.find<GetTableStatusUseCase>(),
        Get.find<GetProcessingOrderUseCase>(),
        Get.find<SaveKotOrderUseCase>(),
        Get.find<SaveKotUseCase>(),
        Get.find<RemoveKotProductUseCase>(),
        Get.find<RemoveKotQuantityUseCase>(),
        Get.find<TakeAwayHoldUseCase>(),
        Get.find<TakeAwaySaveOrderUseCase>(),
        Get.find<GetTakeAwayProcessingUseCase>(),
        Get.find<GetTakeAwayCompletedUseCase>(),
        Get.find<GetTakeAwayCompletedViewUseCase>(),
        Get.find<GetLowStockProductsUseCase>(),
        Get.find<GetOutOfStockProductsUseCase>(),
        Get.find<GetNotificationCountUseCase>(),
      ),
      fenix: true,
    );
  }

  if (!Get.isRegistered<StaffController>()) {
    Get.lazyPut<StaffController>(
      () => StaffController(
        Get.find<GetStaffUseCase>(),
        Get.find<LocalStorageService>(),
      ),
      fenix: true,
    );
  }

  return storage.hasAuthenticatedSession
      ? AppRoutes.homescreen
      : AppRoutes.login;
}

T locate<T>() => Get.find<T>();
