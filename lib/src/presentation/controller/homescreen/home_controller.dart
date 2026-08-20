import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appimages.dart';
import 'package:pick_my_snacks/src/data/model/get_product.dart' as api_model;
import 'package:pick_my_snacks/src/data/model/get_hold.dart';
import 'package:pick_my_snacks/src/data/model/get_resume.dart';
import 'package:pick_my_snacks/src/data/model/get_staff.dart';
import 'package:pick_my_snacks/src/data/model/get_table.dart';
import 'package:pick_my_snacks/src/data/model/get_table_status.dart';
import 'package:pick_my_snacks/src/data/model/get_saveorder.dart';
import 'package:pick_my_snacks/src/data/model/processing.dart';
import 'package:pick_my_snacks/src/data/model/post_kot_model.dart';
import 'package:pick_my_snacks/src/data/model/remove_kot_product.dart';
import 'package:pick_my_snacks/src/data/model/hold_order.dart';
import 'package:pick_my_snacks/src/data/model/save_order.dart';
import 'package:pick_my_snacks/src/data/model/take_away_hold.dart';
import 'package:pick_my_snacks/src/data/model/take_away_processing.dart';
import 'package:pick_my_snacks/src/data/model/take_away_save_order.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_products_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_low_stock_products_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_out_of_stock_products_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_notification_count_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_take_away_completed_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_take_away_completed_view_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_tables_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_take_away_processing_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_table_status_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_processing_order_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_kot_order_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_kot_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/delete_held_bill_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_hold_orders_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/hold_order_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/resume_order_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/remove_kot_product_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/remove_kot_quantity_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_order_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/take_away_hold_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/take_away_save_order_usecase.dart';
import 'package:pick_my_snacks/src/presentation/controller/staff/staff_controller.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.image,
    this.productId = '',
    this.stock,
  });

  final int id;
  final String name;
  final String unit;
  final double price;
  final String image;
  final String productId;
  final num? stock;
}

class CartItem {
  CartItem({
    required this.product,
    this.quantity = 1,
    this.scannedWeightCode,
    this.manualWeightKg,
    this.notes = '',
    this.backendRowTotal,
    List<KotProductReference>? kotProductReferences,
    String? uniqueId,
  }) : uniqueId =
           uniqueId ?? '${DateTime.now().microsecondsSinceEpoch}_${product.id}',
       kotProductReferences = kotProductReferences ?? <KotProductReference>[];

  final String uniqueId;
  final Product product;
  int quantity;
  final String? scannedWeightCode;
  double? manualWeightKg;
  String notes;
  final double? backendRowTotal;
  final List<KotProductReference> kotProductReferences;

  int? get scannedWeightGrams =>
      scannedWeightCode == null ? null : int.tryParse(scannedWeightCode!);

  double? get effectiveWeightKg =>
      manualWeightKg ??
      (scannedWeightGrams == null ? null : scannedWeightGrams! / 1000);

  String get displayUnit {
    final manualWeight = manualWeightKg;
    if (manualWeight != null) {
      return '${_formatWeight(manualWeight)}kg';
    }
    final code = scannedWeightCode;
    if (code == null || code.length != 4) {
      return product.unit.replaceAll(RegExp(r'\s+'), '');
    }
    return '${code.substring(0, 1)}.${code.substring(1)}kg';
  }

  num get apiUnitValue {
    final weight = effectiveWeightKg;
    if (weight != null) {
      return double.parse(weight.toStringAsFixed(3));
    }
    return _productUnitParts.value;
  }

  String get apiUnit =>
      effectiveWeightKg == null ? _productUnitParts.unit : 'kg';

  _ProductUnitParts get _productUnitParts =>
      _ProductUnitParts.from(product.unit);

  double get total {
    if (backendRowTotal != null) return backendRowTotal!;
    final weight = effectiveWeightKg;
    final unitAmount = weight == null ? product.price : product.price * weight;
    return unitAmount * quantity;
  }

  num get orderQuantity {
    final weight = effectiveWeightKg;
    if (weight == null) return quantity;
    return double.parse((weight * quantity).toStringAsFixed(3));
  }

  double get editableAmount => orderQuantity.toDouble();

  CartItem copy() => CartItem(
    product: product,
    quantity: quantity,
    scannedWeightCode: scannedWeightCode,
    manualWeightKg: manualWeightKg,
    notes: notes,
    backendRowTotal: backendRowTotal,
    kotProductReferences: List<KotProductReference>.from(kotProductReferences),
    uniqueId: uniqueId,
  );

  static String _formatWeight(double value) {
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class KotProductReference {
  const KotProductReference({required this.orderId, this.detailId});

  final int orderId;
  final int? detailId;
}

class _ProductUnitParts {
  const _ProductUnitParts({required this.value, required this.unit});

  factory _ProductUnitParts.from(String displayUnit) {
    final compact = displayUnit.trim().replaceAll(RegExp(r'\s+'), '');
    final match = RegExp(r'^(\d+(?:\.\d+)?)(.*)$').firstMatch(compact);
    if (match == null) {
      return _ProductUnitParts(value: 1, unit: compact);
    }
    return _ProductUnitParts(
      value: num.tryParse(match.group(1)!) ?? 1,
      unit: match.group(2) ?? '',
    );
  }

  final num value;
  final String unit;
}

class QrAddResult {
  const QrAddResult._({this.item, this.error});

  factory QrAddResult.success(CartItem item) => QrAddResult._(item: item);

  factory QrAddResult.failure(String error) => QrAddResult._(error: error);

  final CartItem? item;
  final String? error;

  bool get isSuccess => item != null;
}

class HeldBill {
  HeldBill({
    required this.id,
    required this.createdAt,
    required this.items,
    this.gst = 0,
    this.discountType = 'none',
    this.discountValue = 0,
    this.discountAmount = 0,
    this.discountOffer = '',
    this.discountReason = '',
    this.charge = 0,
    this.chargeReason = '',
    this.backendSubtotal,
    this.backendTotal,
  });

  final int id;
  final DateTime createdAt;
  final List<CartItem> items;
  final double gst;
  final String discountType;
  final double discountValue;
  final double discountAmount;
  final String discountOffer;
  final String discountReason;
  final double charge;
  final String chargeReason;
  final double? backendSubtotal;
  final double? backendTotal;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal =>
      backendSubtotal ?? items.fold(0, (sum, item) => sum + item.total);
  double get tax => gst;
  double get total =>
      backendTotal ??
      (subtotal + gst - discountAmount + charge)
          .clamp(0, double.infinity)
          .toDouble();
}

enum PosFlow { billing, kot, takeAway }

enum KotStage { tables, details, order }

class KotTableOrder {
  const KotTableOrder({
    required this.tableNumber,
    required this.staffName,
    required this.openedAt,
    required this.items,
    this.staffId,
  });

  final int tableNumber;
  final String staffName;
  final int? staffId;
  final DateTime openedAt;
  final List<CartItem> items;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  KotTableOrder copyWithItems(List<CartItem> value) {
    return KotTableOrder(
      tableNumber: tableNumber,
      staffName: staffName,
      staffId: staffId,
      openedAt: openedAt,
      items: value,
    );
  }

  KotTableOrder copyWithStaff(StaffData staff) {
    final name = staff.name?.trim();
    return KotTableOrder(
      tableNumber: tableNumber,
      staffName: name?.isNotEmpty == true ? name! : 'Staff',
      staffId: staff.id,
      openedAt: openedAt,
      items: items,
    );
  }
}

class HomeController extends GetxController {
  HomeController([
    this._getProductsUseCase,
    this._saveOrderUseCase,
    this._holdOrderUseCase,
    this._getHoldOrdersUseCase,
    this._resumeOrderUseCase,
    this._deleteHeldBillUseCase,
    this._getTablesUseCase,
    this._getTableStatusUseCase,
    this._getProcessingOrderUseCase,
    this._saveKotOrderUseCase,
    this._saveKotUseCase,
    this._removeKotProductUseCase,
    this._removeKotQuantityUseCase,
    this._takeAwayHoldUseCase,
    this._takeAwaySaveOrderUseCase,
    this._getTakeAwayProcessingUseCase,
    this._getTakeAwayCompletedUseCase,
    this._getTakeAwayCompletedViewUseCase,
    this._getLowStockProductsUseCase,
    this._getOutOfStockProductsUseCase,
    this._getNotificationCountUseCase,
  ]);

  final GetProductsUseCase? _getProductsUseCase;
  final SaveOrderUseCase? _saveOrderUseCase;
  final HoldOrderUseCase? _holdOrderUseCase;
  final GetHoldOrdersUseCase? _getHoldOrdersUseCase;
  final ResumeOrderUseCase? _resumeOrderUseCase;
  final DeleteHeldBillUseCase? _deleteHeldBillUseCase;
  final GetTablesUseCase? _getTablesUseCase;
  final GetTableStatusUseCase? _getTableStatusUseCase;
  final GetProcessingOrderUseCase? _getProcessingOrderUseCase;
  final SaveKotOrderUseCase? _saveKotOrderUseCase;
  final SaveKotUseCase? _saveKotUseCase;
  final RemoveKotProductUseCase? _removeKotProductUseCase;
  // ignore: unused_field
  final RemoveKotQuantityUseCase? _removeKotQuantityUseCase;
  final TakeAwayHoldUseCase? _takeAwayHoldUseCase;
  final TakeAwaySaveOrderUseCase? _takeAwaySaveOrderUseCase;
  final GetTakeAwayProcessingUseCase? _getTakeAwayProcessingUseCase;
  final GetTakeAwayCompletedUseCase? _getTakeAwayCompletedUseCase;
  final GetTakeAwayCompletedViewUseCase? _getTakeAwayCompletedViewUseCase;
  final GetLowStockProductsUseCase? _getLowStockProductsUseCase;
  final GetOutOfStockProductsUseCase? _getOutOfStockProductsUseCase;
  final GetNotificationCountUseCase? _getNotificationCountUseCase;

  final searchController = TextEditingController();
  final searchQuery = ''.obs;
  final cart = <CartItem>[].obs;
  final heldBills = <HeldBill>[].obs;
  final heldOrderSummaries = <HeldOrderSummary>[].obs;
  final products = <Product>[].obs;
  final apiLowStockProducts = <Product>[].obs;
  final apiOutOfStockProducts = <Product>[].obs;
  final apiStockNotificationCount = 0.obs;
  final isLoadingProducts = false.obs;
  final productError = RxnString();
  final isLoadingLowStockNotifications = false.obs;
  final isLoadingOutOfStockNotifications = false.obs;
  final isLoadingNotificationCount = false.obs;
  final stockNotificationsError = RxnString();
  final outOfStockNotificationsError = RxnString();
  final notificationCountError = RxnString();
  final paymentMethod = 'cash'.obs;
  final isSavingOrder = false.obs;
  final isSavingKotOrder = false.obs;
  final isSyncingTotals = false.obs;
  final saveOrderError = RxnString();
  final kotOrderError = RxnString();
  final lastKotOrder = Rxn<KotOrderData>();
  final lastKitchenOrderItems = <CartItem>[].obs;
  final kitchenSelectedItems = <CartItem>{}.obs;
  final kitchenOrderAwaitingPrint = false.obs;
  final kitchenOrderAwaitingPrintTable = RxnInt();
  final isCompletingKotOrder = false.obs;
  final completeKotOrderError = RxnString();
  final completedKotOrder = Rxn<KotSaveData>();
  final savedOrderNumber = RxnString();
  final isHoldingOrder = false.obs;
  final holdOrderError = RxnString();
  final isLoadingHeldOrders = false.obs;
  final heldOrdersError = RxnString();
  final resumingOrderId = RxnInt();
  final resumeOrderError = RxnString();
  final deletingOrderId = RxnInt();
  final deleteHeldBillError = RxnString();
  final isDeletingKotOrder = false.obs;
  final deleteKotOrderError = RxnString();
  final isRemovingKotProduct = false.obs;
  final removeKotProductError = RxnString();
  final isRemovingKotQuantity = false.obs;
  final removeKotQuantityError = RxnString();
  final isSavingTakeAwayHold = false.obs;
  final takeAwayHoldError = RxnString();
  final takeAwayCustomerName = ''.obs;
  final takeAwayCustomerPhone = ''.obs;
  final isCustomerDetailsPrompted = false.obs;
  final takeAwayHoldOrderId = RxnInt();
  final isSavingTakeAwayOrder = false.obs;
  final takeAwaySaveOrderError = RxnString();
  final isTakeAwayOrderCompleted = false.obs;
  final takeAwayProcessingOrders = <TakeAwayProcessingOrder>[].obs;
  final completedTakeAwayOrders = <TakeAwayProcessingOrder>[].obs;
  final pendingTakeAwayHoldIds = <int>{}.obs;
  final completedTakeAwayHoldIds = <int>{}.obs;
  final isLoadingTakeAwayProcessing = false.obs;
  final takeAwayProcessingError = RxnString();
  final openingPendingTakeAwayOrderId = RxnInt();
  final completingPendingTakeAwayOrderId = RxnInt();
  final isLoadingTakeAwayCompleted = false.obs;
  final takeAwayCompletedError = RxnString();
  final completedTakeAwayOrderView = Rxn<TakeAwayProcessingOrder>();
  final isLoadingCompletedTakeAwayView = false.obs;
  final completedTakeAwayViewError = RxnString();
  final backendSubtotal = RxnDouble();
  final backendGst = RxnDouble();
  final backendTotal = RxnDouble();
  final discountType = 'none'.obs;
  final discountValue = 0.0.obs;
  final discountOffer = ''.obs;
  final discountReason = ''.obs;
  final chargeAmount = 0.0.obs;
  final chargeReason = ''.obs;
  final flow = PosFlow.billing.obs;
  final kotStage = KotStage.tables.obs;
  final activeTableNumber = RxnInt();
  final selectedKotTableNumber = RxnInt();
  final tableOrders = <int, KotTableOrder>{}.obs;
  final submittedKitchenTables = <int>{}.obs;
  final deletedKitchenTables = <int>{}.obs;
  final tables = <TableData>[].obs;
  final isLoadingTables = false.obs;
  final tableError = RxnString();
  final tableStatuses = <int, TableStatusData>{}.obs;
  final isLoadingTableStatuses = false.obs;
  final tableStatusError = RxnString();
  final processingOrder = Rxn<ProcessingOrderData>();
  final processingOrders = <int, ProcessingOrderData>{}.obs;
  final isLoadingProcessingOrder = false.obs;
  final processingOrderError = RxnString();
  int _nextBillId = 1;
  Timer? _totalsSyncTimer;
  Timer? _tableStatusSyncTimer;
  bool _isRefreshingTableStatuses = false;
  Worker? _staffSelectionWorker;
  int _totalsSyncRevision = 0;
  final Set<int> _resumedHeldOrderIds = <int>{};
  final Set<int> _deletedHeldOrderIds = <int>{};
  final Map<int, List<CartItem>> _heldItemSnapshots = <int, List<CartItem>>{};
  final Map<int, Map<String, int>> _kitchenSentQuantities = {};
  final Map<int, Set<int>> _kotHoldOrderIds = {};
  final Set<int> _kotOrdersNeedingReconciliation = <int>{};
  final Set<int> _emptyKotTablesBeingClosed = <int>{};
  final List<CartItem> _completedKotCartSnapshot = <CartItem>[];

  static const paymentMethods = <String>['cash', 'credit', 'card', 'upi'];
  static const num lowStockThreshold = 5;

  List<Product> get lowStockProducts => _getLowStockProductsUseCase != null
      ? apiLowStockProducts.toList(growable: false)
      : products
            .where(
              (product) =>
                  product.stock != null &&
                  product.stock! > 0 &&
                  product.stock! <= lowStockThreshold,
            )
            .toList(growable: false);

  List<Product> get outOfStockProducts => _getOutOfStockProductsUseCase != null
      ? apiOutOfStockProducts.toList(growable: false)
      : products
            .where((product) => product.stock != null && product.stock! <= 0)
            .toList(growable: false);

  bool get isLoadingStockNotifications =>
      isLoadingLowStockNotifications.value ||
      isLoadingOutOfStockNotifications.value ||
      isLoadingNotificationCount.value;

  int get stockNotificationCount => _getNotificationCountUseCase != null
      ? apiStockNotificationCount.value
      : lowStockProducts.length + outOfStockProducts.length;

  List<int> get availableTableNumbers {
    if (_getTablesUseCase == null) {
      return List<int>.generate(10, (index) => index + 1);
    }
    final values =
        tables
            .map((table) => table.displayNumber)
            .whereType<int>()
            .toSet()
            .toList()
          ..sort();
    return values;
  }

  void selectFlow(PosFlow value) {
    final currentFlow = flow.value;
    if (currentFlow == value) {
      if (value == PosFlow.kot) {
        showKotTables();
      }
      return;
    }

    if (currentFlow == PosFlow.kot) {
      // Keep a KOT draft with its table, but never expose that table's cart in
      // Billing or Take Away.
      _syncActiveTableOrder();
      final tableNumber = activeTableNumber.value;
      if (tableNumber != null && tableOrders[tableNumber]?.itemCount == 0) {
        tableOrders.remove(tableNumber);
        submittedKitchenTables.remove(tableNumber);
        _kitchenSentQuantities.remove(tableNumber);
      }
      activeTableNumber.value = null;
      selectedKotTableNumber.value = null;
      processingOrder.value = null;
      kotStage.value = KotStage.tables;
      _restoreStaffAfterKotTable();
    }

    // Each POS flow owns a separate bill. Starting another flow must not carry
    // products, customer details, discounts, or totals from the previous one.
    startNewBill();

    if (value == PosFlow.kot) {
      showKotTables();
    }
    flow.value = value;
    if (value == PosFlow.takeAway) {
      // Take Away is intentionally a demo checkout. Keep product loading live,
      // but discard server-calculated billing values and never sync an order.
      _resetBackendTotals();
    } else if (value == PosFlow.billing) {
      refreshOrderTotals();
    }
  }

  void takeKotTable(
    int tableNumber, {
    required String staffName,
    int? staffId,
  }) {
    if (tableStatuses[tableNumber]?.occupied == true) return;
    final existingOrder = tableOrders[tableNumber];
    if (existingOrder != null && existingOrder.itemCount > 0) return;
    tableOrders.remove(tableNumber);
    submittedKitchenTables.remove(tableNumber);
    deletedKitchenTables.remove(tableNumber);
    _kitchenSentQuantities.remove(tableNumber);
    _kotHoldOrderIds.remove(tableNumber);
    _kotOrdersNeedingReconciliation.remove(tableNumber);
    lastKitchenOrderItems.clear();
    kitchenOrderAwaitingPrint.value = false;
    kitchenOrderAwaitingPrintTable.value = null;
    _syncActiveTableOrder();
    activeTableNumber.value = null;
    startNewBill();
    final order = KotTableOrder(
      tableNumber: tableNumber,
      staffName: staffName.trim().isEmpty ? 'Staff' : staffName.trim(),
      staffId: staffId,
      openedAt: DateTime.now(),
      items: const [],
    );
    tableOrders[tableNumber] = order;
    activeTableNumber.value = tableNumber;
    _useKotTableStaff(staffId: order.staffId, staffName: order.staffName);
    selectedKotTableNumber.value = null;
    processingOrder.value = null;
    flow.value = PosFlow.kot;
    kotStage.value = KotStage.order;
  }

  void continueKotTable(int tableNumber) {
    final order = tableOrders[tableNumber];
    if (order == null) return;
    _syncActiveTableOrder();
    activeTableNumber.value = null;
    startNewBill();
    cart.assignAll(order.items.map((item) => item.copy()));
    _useKotTableStaff(staffId: order.staffId, staffName: order.staffName);
    activeTableNumber.value = tableNumber;
    selectedKotTableNumber.value = null;
    processingOrder.value = null;
    flow.value = PosFlow.kot;
    kotStage.value = KotStage.order;
  }

  void showKotTables() {
    _syncActiveTableOrder();
    final tableNumber = activeTableNumber.value;
    if (tableNumber != null && tableOrders[tableNumber]?.itemCount == 0) {
      tableOrders.remove(tableNumber);
      submittedKitchenTables.remove(tableNumber);
      _kitchenSentQuantities.remove(tableNumber);
      activeTableNumber.value = null;
    }
    selectedKotTableNumber.value = null;
    processingOrder.value = null;
    processingOrderError.value = null;
    kotStage.value = KotStage.tables;
    _restoreStaffAfterKotTable();
    unawaited(refreshKotTables());
  }

  Future<void> showKotTableDetails(int tableNumber) async {
    final hasLocalOrder =
        tableOrders.containsKey(tableNumber) &&
        submittedKitchenTables.contains(tableNumber);
    final hasRemoteOrder = tableStatuses[tableNumber]?.occupied == true;
    if (!hasLocalOrder && !hasRemoteOrder) return;
    selectedKotTableNumber.value = tableNumber;
    processingOrder.value = null;
    processingOrderError.value = null;
    kotStage.value = KotStage.details;
    if (hasLocalOrder) {
      final localOrder = tableOrders[tableNumber];
      if (localOrder != null) {
        _useKotTableStaff(
          staffId: localOrder.staffId,
          staffName: localOrder.staffName,
        );
      }
      return;
    }

    final cachedOrder = processingOrders[tableNumber];
    if (cachedOrder != null) {
      processingOrder.value = cachedOrder;
    } else {
      await getProcessingOrder(tableNumber);
    }
    final remoteOrder = processingOrder.value?.order;
    if (remoteOrder != null) {
      _useKotTableStaff(
        staffId: remoteOrder.staffId,
        staffName: remoteOrder.staffName,
      );
    }
  }

  void startNewKotBill() {
    final tableNumber = activeTableNumber.value;
    if (tableNumber != null) {
      tableOrders.remove(tableNumber);
      submittedKitchenTables.remove(tableNumber);
      _kitchenSentQuantities.remove(tableNumber);
      _kotHoldOrderIds.remove(tableNumber);
      _kotOrdersNeedingReconciliation.remove(tableNumber);
    }
    activeTableNumber.value = null;
    selectedKotTableNumber.value = null;
    processingOrder.value = null;
    lastKitchenOrderItems.clear();
    kitchenOrderAwaitingPrint.value = false;
    kitchenOrderAwaitingPrintTable.value = null;
    startNewBill();
    showKotTables();
  }

  void _syncActiveTableOrder() {
    final tableNumber = activeTableNumber.value;
    if (tableNumber == null) return;
    final order = tableOrders[tableNumber];
    if (order == null) return;
    tableOrders[tableNumber] = order.copyWithItems(
      cart.map((item) => item.copy()).toList(),
    );
  }

  Future<void> getTables() async {
    final useCase = _getTablesUseCase;
    if (useCase == null || isLoadingTables.value) return;

    isLoadingTables.value = true;
    tableError.value = null;
    try {
      final response = await useCase();
      if (response.status == false) {
        tables.clear();
        tableError.value = response.message ?? 'Unable to load tables.';
        return;
      }
      tables.assignAll(
        (response.data ?? const <TableData>[]).where(
          (table) => table.displayNumber != null,
        ),
      );
      await getTableStatuses();
    } catch (_) {
      tables.clear();
      tableError.value = 'Unable to load tables. Please try again.';
    } finally {
      isLoadingTables.value = false;
    }
  }

  Future<void> refreshKotTables() async {
    if (_getTablesUseCase != null) {
      await getTables();
      return;
    }
    await getTableStatuses();
  }

  Future<void> getTableStatuses({bool silent = false}) async {
    final useCase = _getTableStatusUseCase;
    if (useCase == null || _isRefreshingTableStatuses) return;

    _isRefreshingTableStatuses = true;
    if (!silent) {
      isLoadingTableStatuses.value = true;
      tableStatusError.value = null;
    }
    try {
      final response = await useCase();
      if (response.status == false) {
        if (!silent) {
          tableStatuses.clear();
          tableStatusError.value =
              response.message ?? 'Unable to load table status.';
        }
        return;
      }
      final previouslyOccupied = tableStatuses.values
          .where((status) => status.occupied)
          .map((status) => status.tableId)
          .whereType<int>()
          .toSet();
      final statuses = <int, TableStatusData>{};
      for (final status in response.data ?? const <TableStatusData>[]) {
        final tableId = status.tableId;
        if (tableId == null) continue;
        statuses[tableId] = status;
        deletedKitchenTables.remove(tableId);
      }
      tableStatuses.assignAll(statuses);
      tableStatusError.value = null;
      final occupiedTableNumbers = statuses.values
          .where((status) => status.occupied)
          .map((status) => status.tableId)
          .whereType<int>()
          .toSet();
      final closedOnAnotherDevice = previouslyOccupied.difference(
        occupiedTableNumbers,
      );
      if (closedOnAnotherDevice.isNotEmpty) {
        _clearExternallyClosedKotTables(closedOnAnotherDevice);
      }
      final tableNumbersToVerify = silent
          ? occupiedTableNumbers.where(
              (tableId) =>
                  !previouslyOccupied.contains(tableId) ||
                  !processingOrders.containsKey(tableId),
            )
          : occupiedTableNumbers;
      processingOrders.removeWhere(
        (tableNumber, _) => !occupiedTableNumbers.contains(tableNumber),
      );
      await _loadProcessingOrderSummaries(tableNumbersToVerify);

      final selectedTable = selectedKotTableNumber.value;
      if (selectedTable != null &&
          !occupiedTableNumbers.contains(selectedTable) &&
          !submittedKitchenTables.contains(selectedTable)) {
        selectedKotTableNumber.value = null;
        processingOrder.value = null;
        processingOrderError.value = null;
        kotStage.value = KotStage.tables;
      }
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        final staleTableNumbers = <int>{
          ...tableStatuses.values
              .where((status) => status.occupied)
              .map((status) => status.tableId)
              .whereType<int>(),
          ...processingOrders.keys,
          ...submittedKitchenTables,
        };
        tableStatuses.clear();
        _clearExternallyClosedKotTables(staleTableNumbers);
        tableStatusError.value = null;
        return;
      }
      if (!silent) {
        tableStatuses.clear();
        processingOrders.clear();
        tableStatusError.value =
            'Unable to load table status. Please try again.';
      }
    } catch (_) {
      if (!silent) {
        tableStatuses.clear();
        processingOrders.clear();
        tableStatusError.value =
            'Unable to load table status. Please try again.';
      }
    } finally {
      _isRefreshingTableStatuses = false;
      if (!silent) isLoadingTableStatuses.value = false;
    }
  }

  void _clearExternallyClosedKotTables(Set<int> tableNumbers) {
    if (tableNumbers.isEmpty) return;
    final currentTable = activeTableNumber.value;
    final selectedTable = selectedKotTableNumber.value;
    final currentScreenWasClosed =
        (currentTable != null && tableNumbers.contains(currentTable)) ||
        (selectedTable != null && tableNumbers.contains(selectedTable));

    for (final tableId in tableNumbers) {
      tableOrders.remove(tableId);
      tableStatuses.remove(tableId);
      processingOrders.remove(tableId);
      submittedKitchenTables.remove(tableId);
      deletedKitchenTables.add(tableId);
      _kitchenSentQuantities.remove(tableId);
      _kotHoldOrderIds.remove(tableId);
      _kotOrdersNeedingReconciliation.remove(tableId);
    }

    if (!currentScreenWasClosed) return;
    activeTableNumber.value = null;
    selectedKotTableNumber.value = null;
    processingOrder.value = null;
    processingOrderError.value = null;
    lastKitchenOrderItems.clear();
    kitchenOrderAwaitingPrint.value = false;
    kitchenOrderAwaitingPrintTable.value = null;
    startNewBill();
    flow.value = PosFlow.kot;
    kotStage.value = KotStage.tables;
    _restoreStaffAfterKotTable();
  }

  void _startTableStatusSync() {
    if (_getTableStatusUseCase == null) return;
    _tableStatusSyncTimer?.cancel();
    _tableStatusSyncTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(getTableStatuses(silent: true)),
    );
  }

  Future<void> getProcessingOrder(int tableNumber) async {
    final useCase = _getProcessingOrderUseCase;
    if (useCase == null || isLoadingProcessingOrder.value) {
      if (useCase == null) {
        processingOrderError.value = 'Processing-order service is unavailable.';
      }
      return;
    }

    isLoadingProcessingOrder.value = true;
    processingOrderError.value = null;
    try {
      final response = await useCase(tableNumber);
      final data = response.data;
      if (data?.isProcessing == false) {
        processingOrder.value = null;
        processingOrderError.value = null;
        _clearEmptyKotTable(tableNumber);
        return;
      }
      if (response.status == false ||
          data == null ||
          data.isProcessing == false ||
          data.order == null) {
        processingOrder.value = null;
        processingOrderError.value =
            response.message ?? 'No processing order was found.';
        return;
      }
      processingOrder.value = data;
      processingOrders[tableNumber] = data;
    } catch (_) {
      processingOrder.value = null;
      processingOrderError.value =
          'Unable to load the processing order. Please try again.';
    } finally {
      isLoadingProcessingOrder.value = false;
    }
  }

  Future<void> _loadProcessingOrderSummaries(Iterable<int> tableNumbers) async {
    final useCase = _getProcessingOrderUseCase;
    if (useCase == null) return;

    final occupiedTables = tableNumbers.toSet();
    await Future.wait(
      occupiedTables.map((tableNumber) async {
        try {
          final response = await useCase(tableNumber);
          final data = response.data;
          if (response.status != false &&
              data != null &&
              data.isProcessing != false &&
              data.order != null) {
            processingOrders[tableNumber] = data;
          } else {
            processingOrders.remove(tableNumber);
          }
        } catch (_) {
          processingOrders.remove(tableNumber);
        }
      }),
    );
  }

  /// Closes an empty backend KOT bill and releases its table immediately.
  ///
  /// If the close endpoint identifies an empty processing hold, that specific
  /// hold is discarded and the KOT close is retried before local state changes.
  Future<bool> closeEmptyKotTable(int tableId) async {
    if (!_emptyKotTablesBeingClosed.add(tableId)) return false;
    try {
      final closeUseCase = _saveKotUseCase;
      if (closeUseCase != null) {
        final response = await closeUseCase(tableId);
        if (response.status == false) {
          if (_isMissingHoldBill(response.message)) {
            _clearEmptyKotTable(tableId);
            return true;
          }
          log(
            response.message ?? 'Unable to release empty KOT table $tableId.',
            name: 'CloseEmptyKotTable',
          );
          return false;
        }
        _clearEmptyKotTable(tableId);
        return true;
      }

      return false;
    } on DioException catch (error) {
      if (_isMissingHoldBill(_apiResponseMessage(error))) {
        log(
          'No processing KOT remains for table $tableId. Freeing the table.',
          name: 'CloseEmptyKotTable',
        );
        _clearEmptyKotTable(tableId);
        return true;
      }
      log(
        'Unable to close empty KOT table $tableId: ${_saveOrderApiError(error)}',
        name: 'CloseEmptyKotTable',
      );
      return false;
    } catch (error, stackTrace) {
      log(
        'Unable to close empty KOT table $tableId.',
        name: 'CloseEmptyKotTable',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      _emptyKotTablesBeingClosed.remove(tableId);
    }
  }

  void _clearEmptyKotTable(int tableId) {
    tableOrders.remove(tableId);
    tableStatuses.remove(tableId);
    processingOrders.remove(tableId);
    submittedKitchenTables.remove(tableId);
    deletedKitchenTables.add(tableId);
    _kitchenSentQuantities.remove(tableId);
    _kotHoldOrderIds.remove(tableId);
    _kotOrdersNeedingReconciliation.remove(tableId);

    if (activeTableNumber.value == tableId ||
        selectedKotTableNumber.value == tableId) {
      activeTableNumber.value = null;
      selectedKotTableNumber.value = null;
      processingOrder.value = null;
      processingOrderError.value = null;
      lastKitchenOrderItems.clear();
      kitchenOrderAwaitingPrint.value = false;
      kitchenOrderAwaitingPrintTable.value = null;
      startNewBill();
      backendSubtotal.value = 0;
      backendGst.value = 0;
      backendTotal.value = 0;
      flow.value = PosFlow.kot;
      showKotTables();
    }
  }

  void continueProcessingOrder() {
    final data = processingOrder.value;
    final order = data?.order;
    final tableNumber =
        data?.table?.tableId ?? order?.tableId ?? selectedKotTableNumber.value;
    if (order == null || tableNumber == null) return;

    final processingProducts = order.products ?? const <ProcessingProduct>[];
    final items = processingProducts.map((item) {
      final holdOrderId = item.holdOrderId ?? order.id;
      return CartItem(
        product: Product(
          id: item.productId ?? item.id ?? 0,
          productId: item.productCode ?? '',
          name: item.productName?.trim().isNotEmpty == true
              ? item.productName!.trim()
              : 'Unnamed product',
          unit: item.unit ?? '',
          price: item.price ?? item.mrp ?? 0,
          image: '',
        ),
        quantity: item.quantity ?? 1,
        kotProductReferences: holdOrderId == null
            ? null
            : <KotProductReference>[
                KotProductReference(orderId: holdOrderId, detailId: item.id),
              ],
      );
    }).toList();
    tableOrders[tableNumber] = KotTableOrder(
      tableNumber: tableNumber,
      staffName: order.staffName?.trim().isNotEmpty == true
          ? order.staffName!.trim()
          : 'Staff',
      staffId: order.staffId,
      openedAt: DateTime.tryParse(order.createdAt ?? '') ?? DateTime.now(),
      items: items,
    );
    cart.assignAll(items.map((item) => item.copy()));
    _useKotTableStaff(staffId: order.staffId, staffName: order.staffName);
    submittedKitchenTables.add(tableNumber);
    _kitchenSentQuantities[tableNumber] = {
      for (final item in items) item.uniqueId: item.quantity,
    };
    final processingOrderIds = <int>{
      ?order.id,
      ...order.processingOrderIds,
      ...processingProducts
          .map((product) => product.holdOrderId)
          .whereType<int>(),
    };
    if (processingOrderIds.isNotEmpty) {
      _kotHoldOrderIds[tableNumber] = processingOrderIds;
    }
    activeTableNumber.value = tableNumber;
    selectedKotTableNumber.value = null;
    savedOrderNumber.value = order.orderId;
    backendSubtotal.value = order.subtotal;
    backendGst.value = order.gst;
    backendTotal.value = order.total;
    if (paymentMethods.contains(order.paymentMode)) {
      paymentMethod.value = order.paymentMode!;
    }
    flow.value = PosFlow.kot;
    kotStage.value = KotStage.order;
  }

  bool get usesBackendHeldOrders => _getHoldOrdersUseCase != null;

  int get heldBillCount =>
      usesBackendHeldOrders ? heldOrderSummaries.length : heldBills.length;

  static const _previewProducts = <Product>[
    Product(
      id: 1,
      name: 'Bisleri Water Bottle',
      unit: '1L',
      price: 20,
      image: AppImages.water,
      stock: 4,
    ),
    Product(
      id: 2,
      name: 'Coca Cola',
      unit: '500ml',
      price: 40,
      image: AppImages.cola,
      stock: 0,
    ),
    Product(
      id: 3,
      name: "Lay's Classic",
      unit: '52g',
      price: 20,
      image: AppImages.chips,
      stock: 3,
    ),
    Product(
      id: 4,
      name: 'Parle-G Biscuit',
      unit: '100g',
      price: 10,
      image: AppImages.biscuit,
      stock: 12,
    ),
    Product(
      id: 5,
      name: 'Dairy Milk Chocolate',
      unit: '50g',
      price: 30,
      image: AppImages.chocolate,
      stock: 2,
    ),
    Product(
      id: 6,
      name: 'Surf Excel',
      unit: '1kg',
      price: 145,
      image: AppImages.detergent,
      stock: 8,
    ),
    Product(
      id: 7,
      name: 'Colgate Toothpaste',
      unit: '100g',
      price: 45,
      image: AppImages.toothpaste,
      stock: 0,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    _startTableStatusSync();
    if (Get.isRegistered<StaffController>()) {
      _staffSelectionWorker = ever(Get.find<StaffController>().selectedStaff, (
        staff,
      ) {
        _updateActiveKotTableStaff(staff);
        refreshOrderTotals();
      });
    }
    if (_getProductsUseCase == null) {
      _loadPreviewData();
      return;
    }
    unawaited(getProducts());
    if (_getLowStockProductsUseCase != null ||
        _getOutOfStockProductsUseCase != null ||
        _getNotificationCountUseCase != null) {
      unawaited(refreshStockNotifications());
    }
  }

  Future<void> getProducts() async {
    final useCase = _getProductsUseCase;
    if (useCase == null) return;

    isLoadingProducts.value = true;
    productError.value = null;

    try {
      final response = await useCase();
      if (response.success == false) {
        productError.value = response.message ?? 'Unable to load products.';
        products.clear();
        return;
      }

      final apiProducts = response.data ?? const <api_model.Data>[];
      products.assignAll(
        apiProducts
            .asMap()
            .entries
            .where((entry) => entry.value.isActive != false)
            .map((entry) => _mapProduct(entry.key, entry.value)),
      );
    } catch (error) {
      productError.value = 'Unable to load products. Please try again.';
    } finally {
      isLoadingProducts.value = false;
    }
  }

  Future<void> getLowStockProducts() async {
    final useCase = _getLowStockProductsUseCase;
    if (useCase == null || isLoadingLowStockNotifications.value) return;

    isLoadingLowStockNotifications.value = true;
    stockNotificationsError.value = null;
    try {
      final response = await useCase();
      if (response.status == false) {
        stockNotificationsError.value =
            response.message ?? 'Unable to load low-stock products.';
        apiLowStockProducts.clear();
        return;
      }

      final stockProducts = response.data ?? const <api_model.Data>[];
      apiLowStockProducts.assignAll(
        stockProducts.asMap().entries.map(
          (entry) => _mapProduct(entry.key, entry.value),
        ),
      );
    } catch (_) {
      stockNotificationsError.value =
          'Unable to load stock notifications. Please try again.';
    } finally {
      isLoadingLowStockNotifications.value = false;
    }
  }

  Future<void> getOutOfStockProducts() async {
    final useCase = _getOutOfStockProductsUseCase;
    if (useCase == null || isLoadingOutOfStockNotifications.value) return;

    isLoadingOutOfStockNotifications.value = true;
    outOfStockNotificationsError.value = null;
    try {
      final response = await useCase();
      if (response.status == false) {
        outOfStockNotificationsError.value =
            response.message ?? 'Unable to load out-of-stock products.';
        apiOutOfStockProducts.clear();
        return;
      }

      final stockProducts = response.data ?? const <api_model.Data>[];
      apiOutOfStockProducts.assignAll(
        stockProducts.asMap().entries.map(
          (entry) => _mapProduct(entry.key, entry.value),
        ),
      );
    } catch (_) {
      outOfStockNotificationsError.value =
          'Unable to load out-of-stock products. Please try again.';
    } finally {
      isLoadingOutOfStockNotifications.value = false;
    }
  }

  Future<void> getNotificationCount() async {
    final useCase = _getNotificationCountUseCase;
    if (useCase == null || isLoadingNotificationCount.value) return;

    isLoadingNotificationCount.value = true;
    notificationCountError.value = null;
    try {
      final response = await useCase();
      if (response.status == false) {
        notificationCountError.value =
            response.message ?? 'Unable to load the notification count.';
        return;
      }
      apiStockNotificationCount.value = response.count ?? 0;
    } catch (_) {
      notificationCountError.value =
          'Unable to load the notification count. Please try again.';
    } finally {
      isLoadingNotificationCount.value = false;
    }
  }

  Future<void> refreshStockNotifications() async {
    if (_getLowStockProductsUseCase != null ||
        _getOutOfStockProductsUseCase != null ||
        _getNotificationCountUseCase != null) {
      await Future.wait([
        getLowStockProducts(),
        getOutOfStockProducts(),
        getNotificationCount(),
      ]);
      return;
    }
    await getProducts();
  }

  void _loadPreviewData() {
    products.assignAll(_previewProducts);
    cart.assignAll([
      CartItem(product: products[0], quantity: 2),
      CartItem(product: products[2]),
      CartItem(product: products[4]),
    ]);
  }

  Product _mapProduct(int index, api_model.Data item) {
    final unitValue = item.unitValue;
    final formattedUnitValue = unitValue == null
        ? ''
        : unitValue % 1 == 0
        ? unitValue.toInt().toString()
        : unitValue.toString();
    final unit = '$formattedUnitValue${item.unit ?? ''}'.trim();
    final apiImage = item.image?.trim();

    return Product(
      id: item.id ?? index + 1,
      productId: item.productId?.trim() ?? '',
      name: item.productName?.trim().isNotEmpty == true
          ? item.productName!.trim()
          : 'Unnamed product',
      unit: unit,
      price: item.price?.toDouble() ?? 0,
      stock: item.stock,
      image:
          apiImage != null &&
              (apiImage.startsWith('http://') ||
                  apiImage.startsWith('https://'))
          ? apiImage
          : AppImages.defaultProduct,
    );
  }

  List<Product> get filteredProducts {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return products;

    final exactIdMatches = products
        .where((product) => _searchableProductId(product) == query)
        .toList();
    if (exactIdMatches.isNotEmpty) return exactIdMatches;

    return products
        .where(
          (product) =>
              '${_searchableProductId(product)} '
                      '${product.name} ${product.unit}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
  }

  String _searchableProductId(Product product) {
    final apiId = product.productId.trim();
    return (apiId.isEmpty ? '${product.id}' : apiId).toLowerCase();
  }

  int get itemCount => cart.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal =>
      backendSubtotal.value ?? cart.fold(0, (sum, item) => sum + item.total);
  double get tax => backendGst.value ?? 0;
  double get discountAmount {
    final value = discountValue.value;
    if (discountType.value == 'flat') {
      return value.clamp(0, subtotal + tax).toDouble();
    }
    if (discountType.value == 'percentage') {
      return (subtotal * value.clamp(0, 100) / 100)
          .clamp(0, subtotal + tax)
          .toDouble();
    }
    return 0;
  }

  double get total =>
      backendTotal.value ??
      (subtotal + tax - discountAmount + chargeAmount.value)
          .clamp(0, double.infinity)
          .toDouble();

  void applyDiscount({
    required String type,
    required double value,
    String offer = '',
    String reason = '',
  }) {
    discountType.value = type == 'percentage' ? 'percentage' : 'flat';
    discountValue.value = value;
    discountOffer.value = offer.trim();
    discountReason.value = reason.trim();
    _queueOrderTotalsSync();
  }

  void clearDiscount() {
    discountType.value = 'none';
    discountValue.value = 0;
    discountOffer.value = '';
    discountReason.value = '';
    _queueOrderTotalsSync();
  }

  void applyCharge({required double amount, String reason = ''}) {
    chargeAmount.value = amount;
    chargeReason.value = reason.trim();
    _queueOrderTotalsSync();
  }

  void clearCharge() {
    chargeAmount.value = 0;
    chargeReason.value = '';
    _queueOrderTotalsSync();
  }

  Future<bool> saveOrder({required int? staffId}) async {
    final useCase = _saveOrderUseCase;
    if (useCase == null) {
      log('SaveOrderUseCase is not registered.', name: 'SaveOrder');
      return true;
    }

    if (staffId == null) {
      saveOrderError.value = 'Please select a staff member.';
      log(saveOrderError.value!, name: 'SaveOrder');
      return false;
    }
    if (cart.isEmpty) {
      saveOrderError.value = 'Add at least one product to the bill.';
      log(saveOrderError.value!, name: 'SaveOrder');
      return false;
    }

    _cancelTotalsSync();
    log('Starting save order...', name: 'SaveOrder');
    log('Selected staff ID: $staffId', name: 'SaveOrder');
    log('Payment method: ${paymentMethod.value}', name: 'SaveOrder');
    log('Cart item rows: ${cart.length}', name: 'SaveOrder');
    log('Cart total quantity: $itemCount', name: 'SaveOrder');
    log('Subtotal: $subtotal', name: 'SaveOrder');
    log('GST: $tax', name: 'SaveOrder');
    log('Total: $total', name: 'SaveOrder');

    isSavingOrder.value = true;
    saveOrderError.value = null;
    savedOrderNumber.value = null;

    try {
      final response = await useCase(_saveOrderRequest(staffId));
      if (response.status == false) {
        saveOrderError.value = response.message ?? 'Unable to save the order.';
        log(saveOrderError.value!, name: 'SaveOrder');
        return false;
      }
      final order = response.data?.order;
      backendSubtotal.value = order?.subtotal;
      backendGst.value = order?.gst ?? 0;
      backendTotal.value = order?.total ?? subtotal;
      final orderNumber = order?.orderId?.trim();
      if (orderNumber == null || orderNumber.isEmpty) {
        saveOrderError.value =
            'The server did not return an order number. Please try again.';
        log(saveOrderError.value!, name: 'SaveOrder');
        return false;
      }
      savedOrderNumber.value = orderNumber;
      log(
        'Order saved successfully. Order ID: $orderNumber',
        name: 'SaveOrder',
      );
      return true;
    } on DioException catch (error) {
      saveOrderError.value = _saveOrderApiError(error);
      log(
        'Save order failed: ${saveOrderError.value}',
        name: 'SaveOrder',
        error: error,
      );
      return false;
    } catch (error, stackTrace) {
      saveOrderError.value = 'Unable to save the order. Please try again.';
      log(
        'Unexpected save-order error',
        name: 'SaveOrder',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      isSavingOrder.value = false;
    }
  }

  Future<void> getTakeAwayProcessing({int? holdOrderId}) async {
    final useCase = _getTakeAwayProcessingUseCase;
    if (useCase == null) {
      takeAwayProcessingError.value =
          'Take-away processing service is unavailable.';
      return;
    }

    isLoadingTakeAwayProcessing.value = true;
    takeAwayProcessingError.value = null;
    try {
      final targetIds = <int>[];
      if (holdOrderId != null) {
        targetIds.add(holdOrderId);
      } else {
        targetIds.addAll(pendingTakeAwayHoldIds);
        final currentHoldId = takeAwayHoldOrderId.value;
        if (currentHoldId != null && !targetIds.contains(currentHoldId)) {
          targetIds.add(currentHoldId);
        }
      }
      final responses = <TakeAwayProcessingResponse>[];
      if (holdOrderId != null) {
        responses.add(await useCase(holdOrderId));
      } else {
        try {
          // Without an ID, backends that support list mode return every
          // processing take-away bill.
          responses.add(await useCase());
        } catch (_) {
          if (targetIds.isEmpty) rethrow;
        }
        responses.addAll(await Future.wait(targetIds.map((id) => useCase(id))));
      }
      final failedResponse = responses.firstWhereOrNull(
        (response) => response.status == false,
      );
      final orders = responses
          .expand((response) => response.orders)
          .fold(<String, TakeAwayProcessingOrder>{}, (unique, order) {
            unique['${order.id ?? ''}|${order.orderId ?? ''}'] = order;
            return unique;
          })
          .values
          .toList();
      if (failedResponse != null && orders.isEmpty) {
        takeAwayProcessingError.value =
            failedResponse.message ??
            'Unable to load pending take-away orders.';
      }
      takeAwayProcessingOrders.assignAll(orders);
    } on DioException catch (error) {
      takeAwayProcessingOrders.clear();
      takeAwayProcessingError.value = _saveOrderApiError(error);
    } catch (error, stackTrace) {
      takeAwayProcessingOrders.clear();
      takeAwayProcessingError.value =
          'Unable to load pending take-away orders. Please try again.';
      log(
        'Unexpected take-away processing error',
        name: 'TakeAwayProcessingController',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      isLoadingTakeAwayProcessing.value = false;
    }
  }

  Future<bool> openPendingTakeAwayOrderForBilling(
    TakeAwayProcessingOrder summary,
  ) async {
    final order = await getPendingTakeAwayOrderDetail(summary);
    if (order == null) return false;
    continuePendingTakeAwayOrder(order);
    return true;
  }

  Future<TakeAwayProcessingOrder?> getPendingTakeAwayOrderDetail(
    TakeAwayProcessingOrder summary,
  ) async {
    final useCase = _getTakeAwayProcessingUseCase;
    final holdOrderId = summary.holdOrderId ?? summary.id;
    if (useCase == null || holdOrderId == null) {
      takeAwayProcessingError.value = useCase == null
          ? 'Take-away processing service is unavailable.'
          : 'The pending order ID is missing.';
      return null;
    }
    if (openingPendingTakeAwayOrderId.value != null) return null;

    openingPendingTakeAwayOrderId.value = holdOrderId;
    takeAwayProcessingError.value = null;
    try {
      final response = await useCase(holdOrderId);
      if (response.status == false || response.orders.isEmpty) {
        takeAwayProcessingError.value =
            response.message ?? 'Unable to load the pending bill.';
        return null;
      }
      final detail = response.orders.firstWhere(
        (order) => order.holdOrderId == holdOrderId || order.id == holdOrderId,
        orElse: () => response.orders.first,
      );
      final order = TakeAwayProcessingOrder(
        id: detail.id ?? summary.id ?? holdOrderId,
        holdOrderId: detail.holdOrderId ?? holdOrderId,
        orderId: detail.orderId ?? summary.orderId,
        customerName: detail.customerName ?? summary.customerName,
        customerPhone: detail.customerPhone ?? summary.customerPhone,
        staffName: detail.staffName ?? summary.staffName,
        status: detail.status ?? summary.status,
        total: detail.total ?? summary.total,
        products: detail.products.isNotEmpty
            ? detail.products
            : summary.products,
      );
      return order;
    } on DioException catch (error) {
      takeAwayProcessingError.value = _saveOrderApiError(error);
      return null;
    } catch (error, stackTrace) {
      takeAwayProcessingError.value =
          'Unable to load the pending bill. Please try again.';
      log(
        'Unexpected pending take-away detail error',
        name: 'TakeAwayProcessingController',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } finally {
      openingPendingTakeAwayOrderId.value = null;
    }
  }

  Future<void> getTakeAwayCompleted({int? holdOrderId}) async {
    final useCase = _getTakeAwayCompletedUseCase;
    if (useCase == null) {
      takeAwayCompletedError.value =
          'Take-away completed-order service is unavailable.';
      return;
    }

    isLoadingTakeAwayCompleted.value = true;
    takeAwayCompletedError.value = null;
    try {
      final targetIds = holdOrderId != null
          ? <int>[holdOrderId]
          : completedTakeAwayHoldIds.toList();
      final responses = <TakeAwayProcessingResponse>[];
      if (holdOrderId != null) {
        responses.add(await useCase(holdOrderId));
      } else {
        try {
          responses.add(await useCase());
        } catch (_) {
          if (targetIds.isEmpty) rethrow;
        }
        responses.addAll(await Future.wait(targetIds.map((id) => useCase(id))));
      }
      final failedResponse = responses.firstWhereOrNull(
        (response) => response.status == false,
      );
      final unique = <String, TakeAwayProcessingOrder>{
        for (final order in completedTakeAwayOrders)
          '${order.id ?? ''}|${order.orderId ?? ''}': order,
      };
      for (final order in responses.expand((response) => response.orders)) {
        unique['${order.id ?? ''}|${order.orderId ?? ''}'] = order;
      }
      if (failedResponse != null && unique.isEmpty) {
        takeAwayCompletedError.value =
            failedResponse.message ??
            'Unable to load completed take-away orders.';
      }
      completedTakeAwayOrders.assignAll(unique.values);
    } on DioException catch (error) {
      takeAwayCompletedError.value = _saveOrderApiError(error);
    } catch (error, stackTrace) {
      takeAwayCompletedError.value =
          'Unable to load completed take-away orders. Please try again.';
      log(
        'Unexpected completed take-away error',
        name: 'TakeAwayCompletedController',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      isLoadingTakeAwayCompleted.value = false;
    }
  }

  Future<void> getCompletedTakeAwayView(
    int completedOrderId,
    int holdOrderId,
  ) async {
    final useCase = _getTakeAwayCompletedViewUseCase;
    if (useCase == null) {
      completedTakeAwayViewError.value =
          'Completed take-away detail service is unavailable.';
      return;
    }
    isLoadingCompletedTakeAwayView.value = true;
    completedTakeAwayViewError.value = null;
    completedTakeAwayOrderView.value = null;
    try {
      final response = await useCase(completedOrderId, holdOrderId);
      if (response.status == false || response.orders.isEmpty) {
        completedTakeAwayViewError.value =
            response.message ?? 'Unable to load the completed order.';
        return;
      }
      completedTakeAwayOrderView.value = response.orders.first;
    } on DioException catch (error) {
      completedTakeAwayViewError.value = _saveOrderApiError(error);
    } catch (error, stackTrace) {
      completedTakeAwayViewError.value =
          'Unable to load the completed order. Please try again.';
      log(
        'Unexpected completed take-away view error',
        name: 'TakeAwayCompletedViewController',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      isLoadingCompletedTakeAwayView.value = false;
    }
  }

  void continuePendingTakeAwayOrder(TakeAwayProcessingOrder order) {
    final holdOrderId = order.holdOrderId ?? order.id;
    if (holdOrderId == null) return;
    startNewBill();
    final items = order.products.map((item) {
      final quantity = double.tryParse(item.quantity ?? '') ?? 1;
      final unit = item.unit?.trim() ?? '';
      final isWeighted = _isKilogramUnit(unit);
      return CartItem(
        product: Product(
          id: item.productId ?? 0,
          name: item.productName?.trim().isNotEmpty == true
              ? item.productName!.trim()
              : 'Product ${item.productId ?? '-'}',
          unit: unit,
          price: item.price ?? 0,
          image: AppImages.defaultProduct,
        ),
        quantity: isWeighted ? 1 : quantity.round(),
        manualWeightKg: isWeighted ? quantity : null,
      );
    }).toList();
    cart.assignAll(items);
    cart.refresh();
    takeAwayHoldOrderId.value = holdOrderId;
    pendingTakeAwayHoldIds.add(holdOrderId);
    savedOrderNumber.value = order.orderId;
    takeAwayCustomerName.value = order.customerName ?? '';
    takeAwayCustomerPhone.value = order.customerPhone ?? '';
    backendSubtotal.value = order.products.fold<double>(
      0,
      (sum, product) => sum + (product.rowTotal ?? 0),
    );
    backendTotal.value = order.total ?? backendSubtotal.value;
    flow.value = PosFlow.takeAway;
  }

  Future<bool> completeTakeAwayOrder({
    int? holdOrderId,
    TakeAwayProcessingOrder? pendingOrder,
  }) async {
    final currentHoldOrderId = takeAwayHoldOrderId.value;
    final targetId = holdOrderId ?? currentHoldOrderId;
    final completesCurrentOrder =
        targetId != null && targetId == currentHoldOrderId;
    if (completesCurrentOrder && isTakeAwayOrderCompleted.value) return true;
    if (isSavingTakeAwayOrder.value) return false;
    final useCase = _takeAwaySaveOrderUseCase;
    if (useCase == null) {
      takeAwaySaveOrderError.value =
          'Take-away checkout service is unavailable.';
      return false;
    }
    if (targetId == null) {
      takeAwaySaveOrderError.value =
          'Send the Kitchen Bill before completing the take-away order.';
      return false;
    }

    isSavingTakeAwayOrder.value = true;
    completingPendingTakeAwayOrderId.value = targetId;
    takeAwaySaveOrderError.value = null;
    try {
      final response = await useCase(
        TakeAwaySaveOrderRequest(holdOrderId: targetId),
      );
      if (response.status == false) {
        takeAwaySaveOrderError.value =
            response.message ?? 'Unable to complete the take-away order.';
        return false;
      }
      final finalOrder = response.order;
      final orderNumber = finalOrder?.orderId?.trim();
      if (orderNumber != null && orderNumber.isNotEmpty) {
        savedOrderNumber.value = orderNumber;
      }
      backendSubtotal.value = finalOrder?.subtotal ?? backendSubtotal.value;
      backendGst.value = finalOrder?.gst ?? backendGst.value;
      backendTotal.value = finalOrder?.total ?? backendTotal.value;
      completedTakeAwayOrders.insert(
        0,
        TakeAwayProcessingOrder(
          id: finalOrder?.id ?? pendingOrder?.id ?? targetId,
          holdOrderId: pendingOrder?.holdOrderId ?? targetId,
          orderId:
              finalOrder?.orderId ??
              pendingOrder?.orderId ??
              savedOrderNumber.value,
          customerName:
              pendingOrder?.customerName ?? takeAwayCustomerName.value,
          customerPhone:
              pendingOrder?.customerPhone ?? takeAwayCustomerPhone.value,
          staffName: pendingOrder?.staffName,
          status: finalOrder?.status ?? 'completed',
          total: finalOrder?.total ?? backendTotal.value,
          products:
              pendingOrder?.products ??
              cart
                  .map(
                    (item) => TakeAwayProcessingProduct(
                      productId: item.product.id,
                      productName: item.product.name,
                      quantity: item.orderQuantity.toString(),
                      unit: item.apiUnit,
                    ),
                  )
                  .toList(),
        ),
      );
      pendingTakeAwayHoldIds.remove(targetId);
      completedTakeAwayHoldIds.add(targetId);
      takeAwayProcessingOrders.removeWhere(
        (order) => (order.holdOrderId ?? order.id) == targetId,
      );
      if (completesCurrentOrder) isTakeAwayOrderCompleted.value = true;
      log(
        'Take-away order completed from hold $targetId.',
        name: 'TakeAwaySaveOrderController',
      );
      return true;
    } on DioException catch (error) {
      takeAwaySaveOrderError.value = _saveOrderApiError(error);
      log(
        'Take-away checkout failed: ${takeAwaySaveOrderError.value}',
        name: 'TakeAwaySaveOrderController',
        error: error,
      );
      return false;
    } catch (error, stackTrace) {
      takeAwaySaveOrderError.value =
          'Unable to complete the take-away order. Please try again.';
      log(
        'Unexpected take-away checkout error',
        name: 'TakeAwaySaveOrderController',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      isSavingTakeAwayOrder.value = false;
      completingPendingTakeAwayOrderId.value = null;
    }
  }

  Future<bool> saveKitchenOrder({
    required int? staffId,
    bool selectedOnly = false,
    bool prepareForKitchenPrint = true,
    bool markAsKitchen = true,
  }) async {
    final useCase = _saveKotOrderUseCase;
    if (useCase == null) {
      kotOrderError.value = 'Kitchen order service is not registered.';
      return false;
    }
    final tableId = activeTableNumber.value;
    if (tableId == null) {
      kotOrderError.value = 'Please select a table.';
      return false;
    }
    if (staffId == null) {
      kotOrderError.value = 'Please select a staff member.';
      return false;
    }
    if (cart.isEmpty) {
      kotOrderError.value = 'Add at least one product to the bill.';
      return false;
    }
    final awaitingPrintItems =
        prepareForKitchenPrint && hasKitchenOrderAwaitingPrint
        ? lastKitchenOrderItems.map((item) => item.copy()).toList()
        : <CartItem>[];
    final pendingItems = selectedOnly
        ? selectedPendingKitchenItems
        : pendingKitchenItems;
    if (pendingItems.isEmpty) {
      if (awaitingPrintItems.isNotEmpty) return true;
      kotOrderError.value = selectedOnly
          ? 'Select at least one new product to send.'
          : 'No new kitchen items to send.';
      return false;
    }

    isSavingKotOrder.value = true;
    kotOrderError.value = null;
    try {
      final response = await useCase(
        KotOrderRequest(
          tableId: tableId,
          staffId: staffId,
          paymentMode: paymentMethod.value,
          discountType: discountType.value,
          discountValue: discountValue.value,
          offer: discountOffer.value,
          discountReason: discountReason.value,
          charge: chargeAmount.value,
          chargeReason: chargeReason.value,
          customerName: takeAwayCustomerName.value,
          customerPhone: takeAwayCustomerPhone.value,
          isKot: markAsKitchen,
          products: pendingItems
              .map(
                (item) => SaveOrderProductRequest(
                  productId: item.product.id,
                  quantity: item.orderQuantity,
                  unitValue: item.apiUnitValue,
                  unit: item.apiUnit,
                  note: item.notes.trim(),
                  isKot: markAsKitchen
                      ? true
                      : kitchenSelectedItems.any(
                          (selected) => selected.uniqueId == item.uniqueId,
                        ),
                ),
              )
              .toList(),
        ),
      );
      final order = response.data?.order;
      final orderNumber = order?.orderId?.trim();
      if (response.status == false ||
          order == null ||
          orderNumber == null ||
          orderNumber.isEmpty) {
        kotOrderError.value =
            response.message ?? 'Unable to save the kitchen order.';
        return false;
      }
      lastKotOrder.value = response.data;
      savedOrderNumber.value = orderNumber;
      backendSubtotal.value = null;
      backendGst.value = null;
      backendTotal.value = null;
      final sentQuantities = _kitchenSentQuantities.putIfAbsent(
        tableId,
        () => <String, int>{},
      );
      for (final item in pendingItems) {
        final itemKey = item.uniqueId;
        sentQuantities[itemKey] =
            (sentQuantities[itemKey] ?? 0) + item.quantity;
      }
      submittedKitchenTables.add(tableId);
      deletedKitchenTables.remove(tableId);
      final holdOrderId = order.id;
      final responseProducts = List<KotProduct>.from(
        order.products ?? const <KotProduct>[],
      );
      final responseOrderIds = <int>{
        ?holdOrderId,
        ...responseProducts.map((product) => product.orderId).whereType<int>(),
      };
      if (responseOrderIds.isNotEmpty) {
        _kotHoldOrderIds
            .putIfAbsent(tableId, () => <int>{})
            .addAll(responseOrderIds);
      }
      for (final pendingItem in pendingItems) {
        final cartItem = cart.firstWhereOrNull(
          (item) => item.uniqueId == pendingItem.uniqueId,
        );
        if (cartItem == null) continue;
        final responseIndex = responseProducts.indexWhere(
          (product) => product.productId == pendingItem.product.id,
        );
        final responseProduct = responseIndex < 0
            ? null
            : responseProducts.removeAt(responseIndex);
        final referenceOrderId = responseProduct?.orderId ?? holdOrderId;
        if (referenceOrderId != null) {
          cartItem.kotProductReferences.add(
            KotProductReference(
              orderId: referenceOrderId,
              detailId: responseProduct?.id,
            ),
          );
        }
      }
      if (prepareForKitchenPrint) {
        lastKitchenOrderItems.assignAll(<CartItem>[
          ...awaitingPrintItems,
          ...pendingItems.map((item) => item.copy()),
        ]);
        kitchenOrderAwaitingPrint.value = true;
        kitchenOrderAwaitingPrintTable.value = tableId;
      } else {
        lastKitchenOrderItems.clear();
        kitchenOrderAwaitingPrint.value = false;
        kitchenOrderAwaitingPrintTable.value = null;
      }
      return true;
    } on DioException catch (error) {
      kotOrderError.value = _saveOrderApiError(error);
      return false;
    } catch (_) {
      kotOrderError.value =
          'Unable to save the kitchen order. Please try again.';
      return false;
    } finally {
      isSavingKotOrder.value = false;
    }
  }

  Future<bool> saveTakeAwayKitchenBill({
    required int? staffId,
    bool selectedOnly = true,
    bool markAsKitchen = true,
  }) async {
    if (isSavingTakeAwayHold.value) return false;
    if (takeAwayHoldOrderId.value != null) {
      takeAwayHoldError.value =
          'This take-away Kitchen Bill is already in Pending orders.';
      return false;
    }
    final useCase = _takeAwayHoldUseCase;
    if (useCase == null) {
      takeAwayHoldError.value = 'Take-away kitchen service is unavailable.';
      return false;
    }
    if (staffId == null) {
      takeAwayHoldError.value = 'Please select a staff member.';
      return false;
    }
    if (takeAwayCustomerName.value.trim().isEmpty ||
        takeAwayCustomerPhone.value.trim().isEmpty) {
      takeAwayHoldError.value = 'Customer name and phone number are required.';
      return false;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(takeAwayCustomerPhone.value.trim())) {
      takeAwayHoldError.value =
          'Customer phone number must be exactly 10 digits.';
      return false;
    }

    final kitchenSelectedItems = cart
        .where(isKitchenItemSelected)
        .toList(growable: false);
    final pendingItems = selectedOnly
        ? kitchenSelectedItems
        : cart.toList(growable: false);
    if (pendingItems.isEmpty) {
      takeAwayHoldError.value = selectedOnly
          ? 'Select at least one product for the Kitchen Bill.'
          : 'Add at least one product to the take-away order.';
      return false;
    }

    isSavingTakeAwayHold.value = true;
    takeAwayHoldError.value = null;
    try {
      final response = await useCase(
        TakeAwayHoldRequest(
          staffId: staffId,
          customerName: takeAwayCustomerName.value,
          customerPhone: takeAwayCustomerPhone.value,
          paymentMode: paymentMethod.value,
          charge: chargeAmount.value,
          discountType: discountType.value,
          discountValue: discountValue.value,
          products: pendingItems
              .map(
                (item) => SaveOrderProductRequest(
                  productId: item.product.id,
                  quantity: item.orderQuantity,
                  unitValue: item.apiUnitValue,
                  unit: item.apiUnit,
                  note: item.notes.trim(),
                  isKot: markAsKitchen
                      ? true
                      : kitchenSelectedItems.any(
                          (selected) => selected.uniqueId == item.uniqueId,
                        ),
                ),
              )
              .toList(),
        ),
      );
      final order = response.data?.order;
      final orderNumber = order?.orderId?.trim();
      if (response.status == false ||
          orderNumber == null ||
          orderNumber.isEmpty) {
        takeAwayHoldError.value =
            response.message ?? 'Unable to create the take-away kitchen bill.';
        return false;
      }

      savedOrderNumber.value = orderNumber;
      final holdId = order?.id;
      takeAwayHoldOrderId.value = holdId;
      if (holdId != null) pendingTakeAwayHoldIds.add(holdId);
      isTakeAwayOrderCompleted.value = false;
      backendSubtotal.value = order?.subtotal;
      backendGst.value = order?.gst;
      backendTotal.value = order?.total;
      lastKitchenOrderItems.assignAll(
        kitchenSelectedItems.map((item) => item.copy()),
      );
      log(
        'Take-away kitchen bill saved. Order ID: $orderNumber',
        name: 'TakeAwayHoldController',
      );
      return true;
    } on DioException catch (error) {
      takeAwayHoldError.value = _saveOrderApiError(error);
      log(
        'Take-away hold failed: ${takeAwayHoldError.value}',
        name: 'TakeAwayHoldController',
        error: error,
      );
      return false;
    } catch (error, stackTrace) {
      takeAwayHoldError.value =
          'Unable to create the take-away kitchen bill. Please try again.';
      log(
        'Unexpected take-away hold error',
        name: 'TakeAwayHoldController',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      isSavingTakeAwayHold.value = false;
    }
  }

  Future<bool> prepareTakeAwayOrderForCompletion({
    required int? staffId,
  }) async {
    if (takeAwayHoldOrderId.value != null) return true;
    return saveTakeAwayKitchenBill(
      staffId: staffId,
      selectedOnly: false,
      markAsKitchen: false,
    );
  }

  Future<bool> holdActiveKotTable({required int? staffId}) async {
    final tableId = activeTableNumber.value;
    if (tableId == null) {
      kotOrderError.value = 'Please select a table.';
      return false;
    }
    if (cart.isEmpty) {
      kotOrderError.value = 'Add at least one product to the bill.';
      return false;
    }

    if (pendingKitchenItems.isNotEmpty) {
      final saved = await saveKitchenOrder(
        staffId: staffId,
        prepareForKitchenPrint: false,
      );
      if (!saved) return false;
    } else if (!submittedKitchenTables.contains(tableId)) {
      kotOrderError.value = 'Unable to hold the table before saving its order.';
      return false;
    }

    lastKitchenOrderItems.clear();
    kitchenOrderAwaitingPrint.value = false;
    kitchenOrderAwaitingPrintTable.value = null;
    final currentStatus = tableStatuses[tableId];
    tableStatuses[tableId] = TableStatusData(
      id: currentStatus?.id,
      tableId: tableId,
      tableStatus: 'Occupied',
      isOccupied: 1,
    );
    showKotTables();
    return true;
  }

  List<CartItem> get pendingKitchenItems {
    return _pendingKitchenItems();
  }

  List<CartItem> get selectedPendingKitchenItems {
    return _pendingKitchenItems(selectedOnly: true);
  }

  bool get hasSelectedPendingKitchenItems =>
      selectedPendingKitchenItems.isNotEmpty;

  List<CartItem> _pendingKitchenItems({bool selectedOnly = false}) {
    final tableId = activeTableNumber.value;
    if (tableId == null) return const [];
    final sentQuantities =
        _kitchenSentQuantities[tableId] ?? const <String, int>{};
    return cart
        .map((item) {
          if (selectedOnly && !kitchenSelectedItems.contains(item)) {
            return null;
          }
          final pendingQuantity =
              item.quantity - (sentQuantities[item.uniqueId] ?? 0);
          if (pendingQuantity <= 0) return null;
          return item.copy()..quantity = pendingQuantity;
        })
        .whereType<CartItem>()
        .toList();
  }

  bool isKitchenItemSelected(CartItem item) =>
      kitchenSelectedItems.contains(item);

  void setKitchenItemSelected(CartItem item, bool selected) {
    if (selected) {
      kitchenSelectedItems.add(item);
    } else {
      kitchenSelectedItems.remove(item);
    }
  }

  bool get hasKitchenOrderAwaitingPrint =>
      kitchenOrderAwaitingPrint.value &&
      kitchenOrderAwaitingPrintTable.value == activeTableNumber.value &&
      lastKitchenOrderItems.isNotEmpty;

  void confirmKitchenOrderPrinted() {
    lastKitchenOrderItems.clear();
    kitchenOrderAwaitingPrint.value = false;
    kitchenOrderAwaitingPrintTable.value = null;
  }

  Future<bool> completeKotOrder({
    int? tableId,
    int? staffId,
    bool recoverMissingHold = true,
  }) async {
    final useCase = _saveKotUseCase;
    if (useCase == null) {
      completeKotOrderError.value = 'KOT completion service is not registered.';
      return false;
    }
    final selectedTableId =
        tableId ?? activeTableNumber.value ?? selectedKotTableNumber.value;
    if (selectedTableId == null) {
      completeKotOrderError.value = 'Please select a table.';
      return false;
    }

    isCompletingKotOrder.value = true;
    completeKotOrderError.value = null;
    try {
      final response = recoverMissingHold
          ? await _completeKotWithMissingHoldRecovery(
              useCase,
              selectedTableId,
              staffId: staffId,
            )
          : await useCase(selectedTableId);
      final data = response.data;
      final order = data?.completedOrder;
      if (response.status == false || data == null || order == null) {
        completeKotOrderError.value =
            response.message ?? 'Unable to complete the KOT order.';
        return false;
      }
      completedKotOrder.value = data;
      _completedKotCartSnapshot
        ..clear()
        ..addAll(cart.map((item) => item.copy()));
      savedOrderNumber.value = order.orderId;
      backendSubtotal.value = order.subtotal;
      backendGst.value = order.gst ?? 0;
      backendTotal.value = order.total;
      return true;
    } on DioException catch (error) {
      completeKotOrderError.value = _saveOrderApiError(error);
      return false;
    } catch (_) {
      completeKotOrderError.value =
          'Unable to complete the KOT order. Please try again.';
      return false;
    } finally {
      isCompletingKotOrder.value = false;
    }
  }

  Future<KotSaveResponse> _completeKotWithMissingHoldRecovery(
    SaveKotUseCase useCase,
    int tableId, {
    required int? staffId,
  }) async {
    try {
      final response = await useCase(tableId);
      if (response.status != false || !_isMissingHoldBill(response.message)) {
        return response;
      }
    } on DioException catch (error) {
      if (!_isMissingHoldBill(_apiResponseMessage(error))) rethrow;
    }

    if (!await _recreateMissingKotHold(tableId, staffId: staffId)) {
      return KotSaveResponse(
        status: false,
        message:
            kotOrderError.value ?? 'Unable to restore the KOT before closing.',
      );
    }
    return useCase(tableId);
  }

  Future<bool> _recreateMissingKotHold(
    int tableId, {
    required int? staffId,
  }) async {
    if (activeTableNumber.value != tableId || cart.isEmpty) return false;
    log(
      'Backend KOT hold for table $tableId is missing. Recreating it from '
      'the current KOT cart before closing.',
      name: 'CompleteKotOrder',
    );
    _kotHoldOrderIds.remove(tableId);
    _kitchenSentQuantities.remove(tableId);
    submittedKitchenTables.remove(tableId);
    processingOrders.remove(tableId);
    processingOrder.value = null;
    lastKotOrder.value = null;
    _kotOrdersNeedingReconciliation.remove(tableId);
    return saveKitchenOrder(staffId: staffId, prepareForKitchenPrint: false);
  }

  static String? _apiResponseMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) return data['message']?.toString();
    return data?.toString();
  }

  /// Ensures locally edited KOT rows were synchronized through KOT endpoints.
  ///
  /// Whole-order reconciliation cannot use `delete_hold_bill`, because that
  /// endpoint belongs exclusively to regular held billing.
  Future<bool> reconcileEditedKotOrder({required int? staffId}) async {
    final tableId = activeTableNumber.value;
    if (tableId == null || !_kotOrdersNeedingReconciliation.contains(tableId)) {
      return true;
    }
    kotOrderError.value =
        'This KOT has an unsynchronized edit. Refresh the table and update it '
        'using the KOT product or quantity controls before closing.';
    log(kotOrderError.value!, name: 'ReconcileKotOrder');
    return false;
  }

  /// Makes sure the backend has every cart row before the KOT is completed.
  ///
  /// The Kitchen Bill can intentionally send only selected products. Any
  /// unselected rows must still be saved when the final bill is closed,
  /// otherwise the backend total covers only the selected subset.
  Future<bool> prepareKotOrderForCompletion({required int? staffId}) async {
    if (!await reconcileEditedKotOrder(staffId: staffId)) return false;
    if (pendingKitchenItems.isEmpty) return true;
    return saveKitchenOrder(
      staffId: staffId,
      prepareForKitchenPrint: false,
      markAsKitchen: false,
    );
  }

  static bool _isMissingHoldBill(String? message) {
    final normalized = message?.trim().toLowerCase() ?? '';
    return normalized.contains('hold bill') &&
        (normalized.contains('not found') ||
            normalized.contains('does not exist') ||
            normalized.contains('already deleted'));
  }

  /// Builds receipt rows from the completed backend order when it contains the
  /// full KOT cart. Some close responses contain only the most recent hold, so
  /// the close-time cart snapshot is used to keep earlier kitchen items on the
  /// final bill.
  List<CartItem> get completedReceiptItems {
    final products = completedKotOrder.value?.completedOrder?.products;
    final backendItems = (products ?? const <KotSavedProduct>[]).map((item) {
      final quantity = item.quantity ?? 1;
      final safeQuantity = quantity > 0 ? quantity : 1;
      final rowTotal = item.rowTotal;
      final backendRate =
          item.price ??
          item.mrp ??
          (rowTotal == null ? 0 : rowTotal / safeQuantity);
      final unitValue = item.unitValue;
      final unit = item.unit?.trim() ?? '';
      final displayUnit = unitValue == null
          ? unit
          : '${_formatBackendNumber(unitValue)}$unit';
      return CartItem(
        product: Product(
          id: item.productId ?? item.id ?? 0,
          productId: item.productCode ?? '',
          name: item.productName?.trim().isNotEmpty == true
              ? item.productName!.trim()
              : 'Unnamed product',
          unit: displayUnit,
          price: backendRate,
          image: '',
        ),
        quantity: safeQuantity,
        backendRowTotal: rowTotal,
      );
    }).toList();

    if (_completedKotCartSnapshot.isEmpty ||
        _backendReceiptCoversCart(backendItems, _completedKotCartSnapshot)) {
      return backendItems;
    }
    return _completedKotCartSnapshot.map((item) => item.copy()).toList();
  }

  bool _backendReceiptCoversCart(
    List<CartItem> backendItems,
    List<CartItem> cartItems,
  ) {
    final backendQuantities = <int, int>{};
    for (final item in backendItems) {
      backendQuantities.update(
        item.product.id,
        (quantity) => quantity + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }
    final cartQuantities = <int, int>{};
    for (final item in cartItems) {
      cartQuantities.update(
        item.product.id,
        (quantity) => quantity + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }
    return cartQuantities.entries.every(
      (entry) => (backendQuantities[entry.key] ?? 0) >= entry.value,
    );
  }

  static String _formatBackendNumber(double value) => value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');

  void finishCompletedKotOrder() {
    final tableId = activeTableNumber.value ?? selectedKotTableNumber.value;
    if (tableId != null) {
      tableOrders.remove(tableId);
      tableStatuses.remove(tableId);
      processingOrders.remove(tableId);
      submittedKitchenTables.remove(tableId);
      deletedKitchenTables.add(tableId);
      _kitchenSentQuantities.remove(tableId);
      _kotHoldOrderIds.remove(tableId);
      _kotOrdersNeedingReconciliation.remove(tableId);
    }
    activeTableNumber.value = null;
    selectedKotTableNumber.value = null;
    processingOrder.value = null;
    processingOrderError.value = null;
    lastKitchenOrderItems.clear();
    _completedKotCartSnapshot.clear();
    kitchenOrderAwaitingPrint.value = false;
    kitchenOrderAwaitingPrintTable.value = null;
    startNewBill();
    flow.value = PosFlow.kot;
    showKotTables();
  }

  Future<bool> deleteActiveKotOrder() async {
    final tableId = activeTableNumber.value ?? selectedKotTableNumber.value;
    if (tableId == null) return false;
    isDeletingKotOrder.value = true;
    deleteKotOrderError.value = null;
    try {
      _clearDeletedKotOrder(tableId);
      log(
        'Deleted KOT for table $tableId from local state only.',
        name: 'DeleteKotOrder',
      );
      return true;
    } catch (_) {
      deleteKotOrderError.value =
          'Unable to delete the kitchen order. Please try again.';
      return false;
    } finally {
      isDeletingKotOrder.value = false;
    }
  }

  void _clearDeletedKotOrder(int tableId) {
    tableOrders.remove(tableId);
    tableStatuses.remove(tableId);
    processingOrders.remove(tableId);
    submittedKitchenTables.remove(tableId);
    deletedKitchenTables.add(tableId);
    _kitchenSentQuantities.remove(tableId);
    _kotHoldOrderIds.remove(tableId);
    _kotOrdersNeedingReconciliation.remove(tableId);
    activeTableNumber.value = null;
    selectedKotTableNumber.value = null;
    processingOrder.value = null;
    processingOrderError.value = null;
    lastKitchenOrderItems.clear();
    kitchenOrderAwaitingPrint.value = false;
    kitchenOrderAwaitingPrintTable.value = null;
    startNewBill();
    flow.value = PosFlow.kot;
    showKotTables();
  }

  String _saveOrderApiError(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map) {
        final messages = errors.values
            .expand(
              (value) => value is List
                  ? value.map((item) => item.toString())
                  : <String>[value.toString()],
            )
            .where((message) => message.trim().isNotEmpty)
            .toList();
        if (messages.isNotEmpty) return messages.join('\n');
      }

      final message = data['message']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
    }
    return 'Unable to save the order. Please try again.';
  }

  Future<HeldBill?> holdOrder({required int? staffId}) async {
    final useCase = _holdOrderUseCase;
    if (useCase == null) return holdCurrentBill();

    if (staffId == null) {
      holdOrderError.value = 'Please select a staff member.';
      log(holdOrderError.value!, name: 'HoldOrder');
      return null;
    }
    if (cart.isEmpty) {
      holdOrderError.value = 'Add at least one product to the bill.';
      log(holdOrderError.value!, name: 'HoldOrder');
      return null;
    }

    log('Starting hold order...', name: 'HoldOrder');
    log('Selected staff ID: $staffId', name: 'HoldOrder');
    log('Payment method: ${paymentMethod.value}', name: 'HoldOrder');
    log('Cart item rows: ${cart.length}', name: 'HoldOrder');
    log('Cart total quantity: $itemCount', name: 'HoldOrder');
    log('Subtotal: $subtotal', name: 'HoldOrder');
    log('GST: $tax', name: 'HoldOrder');
    log('Total: $total', name: 'HoldOrder');

    isHoldingOrder.value = true;
    holdOrderError.value = null;

    try {
      final response = await useCase(
        HoldOrderRequest(
          staffId: staffId,
          discountType: discountType.value,
          discountValue: discountValue.value,
          offer: discountOffer.value,
          discountReason: discountReason.value,
          charge: chargeAmount.value,
          chargeReason: chargeReason.value,
          paymentMode: paymentMethod.value,
          products: cart
              .map(
                (item) => SaveOrderProductRequest(
                  productId: item.product.id,
                  quantity: item.orderQuantity,
                  unitValue: item.apiUnitValue,
                  unit: item.apiUnit,
                ),
              )
              .toList(),
        ),
      );
      if (response.status == false) {
        holdOrderError.value = response.message ?? 'Unable to hold the order.';
        log(holdOrderError.value!, name: 'HoldOrder');
        return null;
      }

      final order = response.data?.order;
      final bill = holdCurrentBill(
        id: order?.id,
        subtotal: order?.subtotal,
        gst: order?.gst ?? 0,
        total: order?.total,
      );
      _heldItemSnapshots[bill.id] = bill.items
          .map((item) => item.copy())
          .toList();
      log(
        'Order held successfully. Order ID: ${order?.orderId}',
        name: 'HoldOrder',
      );
      await getHoldOrders();
      return bill;
    } on DioException catch (error) {
      holdOrderError.value = _saveOrderApiError(error);
      log(
        'Hold order failed: ${holdOrderError.value}',
        name: 'HoldOrder',
        error: error,
      );
      return null;
    } catch (error, stackTrace) {
      holdOrderError.value = 'Unable to hold the order. Please try again.';
      log(
        'Unexpected hold-order error',
        name: 'HoldOrder',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } finally {
      isHoldingOrder.value = false;
    }
  }

  Future<void> getHoldOrders() async {
    final useCase = _getHoldOrdersUseCase;
    if (useCase == null) return;

    isLoadingHeldOrders.value = true;
    heldOrdersError.value = null;
    heldOrderSummaries.clear();
    heldBills.clear();
    try {
      final response = await useCase();
      if (response.status == false) {
        heldOrderSummaries.clear();
        heldOrdersError.value =
            response.message ?? 'Unable to load held orders.';
        return;
      }
      final orders = response.data ?? const <HeldOrderSummary>[];
      heldOrderSummaries.assignAll(
        orders.where(
          (order) =>
              order.id == null ||
              (!_resumedHeldOrderIds.contains(order.id) &&
                  !_deletedHeldOrderIds.contains(order.id)),
        ),
      );
      final hiddenCount = orders.length - heldOrderSummaries.length;
      if (hiddenCount > 0) {
        log(
          'Filtered $hiddenCount previously resumed order(s) from Held Bills.',
          name: 'GetHoldOrders',
        );
      }
    } on DioException catch (error) {
      heldOrdersError.value = _saveOrderApiError(error);
    } catch (error, stackTrace) {
      heldOrdersError.value = 'Unable to load held orders. Please try again.';
      log(
        'Unexpected get-held-orders error',
        name: 'GetHoldOrders',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      isLoadingHeldOrders.value = false;
    }
  }

  Future<bool> resumeHeldOrder(HeldOrderSummary summary) async {
    final useCase = _resumeOrderUseCase;
    final orderId = summary.id;
    if (useCase == null || orderId == null) {
      resumeOrderError.value = 'Unable to identify the held order.';
      return false;
    }

    resumingOrderId.value = orderId;
    resumeOrderError.value = null;
    try {
      final response = await useCase(orderId);
      if (response.status == false) {
        resumeOrderError.value =
            response.message ?? 'Unable to resume the order.';
        return false;
      }

      final data = response.data;
      final apiProducts = data?.products ?? const <ResumedProduct>[];
      if (apiProducts.isEmpty) {
        resumeOrderError.value = 'The held order has no products.';
        return false;
      }

      final heldSnapshot = _heldItemSnapshots.remove(orderId);
      cart.assignAll(
        heldSnapshot ??
            apiProducts.map((item) {
              final unitValue = item.unitValue;
              final formattedUnitValue = unitValue == null
                  ? ''
                  : unitValue % 1 == 0
                  ? unitValue.toInt().toString()
                  : unitValue.toString();
              final name = item.productName?.trim().isNotEmpty == true
                  ? item.productName!.trim()
                  : item.name?.trim().isNotEmpty == true
                  ? item.name!.trim()
                  : 'Unnamed product';
              final product = Product(
                id: item.productId ?? item.id ?? 0,
                productId: item.productCode ?? item.code ?? '',
                name: name,
                unit: '$formattedUnitValue${item.unit ?? ''}'.trim(),
                price: item.price ?? 0,
                image: AppImages.defaultProduct,
              );
              final resumedAmount = (item.qty ?? item.quantity ?? 1).toDouble();
              final isKilogramProduct = _isKilogramUnit(item.unit);
              final resumedWeight =
                  isKilogramProduct &&
                      resumedAmount == 1 &&
                      item.unitValue != null &&
                      item.unitValue! > 0
                  ? item.unitValue!
                  : resumedAmount;
              return CartItem(
                product: product,
                quantity: isKilogramProduct ? 1 : resumedAmount.round(),
                manualWeightKg: isKilogramProduct ? resumedWeight : null,
              );
            }),
      );

      final bill = data?.bill;
      backendSubtotal.value = bill?.subtotal;
      backendGst.value = bill?.gst ?? 0;
      backendTotal.value = bill?.total ?? subtotal;
      final resumedDiscountType = bill?.discountType?.trim().toLowerCase();
      discountType.value =
          resumedDiscountType == 'flat' || resumedDiscountType == 'percentage'
          ? resumedDiscountType!
          : 'none';
      discountValue.value = bill?.discountValue ?? 0;
      discountOffer.value = bill?.offer?.toString() ?? '';
      discountReason.value = bill?.discountReason ?? '';
      chargeAmount.value = bill?.charge ?? 0;
      chargeReason.value = '';
      final payment = bill?.paymentMode?.trim().toLowerCase();
      if (payment != null && paymentMethods.contains(payment)) {
        paymentMethod.value = payment;
      }
      _resumedHeldOrderIds.add(orderId);
      heldOrderSummaries.removeWhere((item) => item.id == orderId);
      log(
        'Order resumed into cart. Order ID: ${bill?.orderId}, '
        'items: ${cart.length}',
        name: 'ResumeOrder',
      );
      return true;
    } on DioException catch (error) {
      resumeOrderError.value = _saveOrderApiError(error);
      return false;
    } catch (error, stackTrace) {
      resumeOrderError.value = 'Unable to resume the order. Please try again.';
      log(
        'Unexpected resume-order error',
        name: 'ResumeOrder',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      resumingOrderId.value = null;
    }
  }

  Future<bool> deleteHeldOrder(HeldOrderSummary summary) async {
    final useCase = _deleteHeldBillUseCase;
    final orderId = summary.id;
    if (useCase == null || orderId == null) {
      deleteHeldBillError.value = 'Unable to identify the held order.';
      return false;
    }

    deletingOrderId.value = orderId;
    deleteHeldBillError.value = null;
    try {
      final response = await useCase(orderId);
      if (response.status == false) {
        deleteHeldBillError.value =
            response.message ?? 'Unable to delete the held order.';
        return false;
      }

      heldOrderSummaries.removeWhere((item) => item.id == orderId);
      heldBills.removeWhere((item) => item.id == orderId);
      _heldItemSnapshots.remove(orderId);
      _deletedHeldOrderIds.add(orderId);
      await getHoldOrders();
      log(
        'Held order deleted. Order ID: ${summary.orderId ?? orderId}',
        name: 'DeleteHeldBill',
      );
      return true;
    } on DioException catch (error) {
      deleteHeldBillError.value = _saveOrderApiError(error);
      return false;
    } catch (error, stackTrace) {
      deleteHeldBillError.value =
          'Unable to delete the held order. Please try again.';
      log(
        'Unexpected delete-held-bill error',
        name: 'DeleteHeldBill',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      deletingOrderId.value = null;
    }
  }

  void addProduct(Product product) {
    final index = cart.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.scannedWeightCode == null &&
          item.kotProductReferences.isEmpty,
    );
    if (index < 0) {
      final item = CartItem(product: product);
      cart.add(item);
    } else {
      cart[index].quantity++;
      cart.refresh();
    }
    _queueOrderTotalsSync();
  }

  QrAddResult addProductFromQr(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      return QrAddResult.failure('The scanned QR code is empty.');
    }

    final directProduct = products.firstWhereOrNull(
      (product) => _matchesQrProductId(product, value),
    );
    if (directProduct != null) {
      addProduct(directProduct);
      final item = cart.firstWhere(
        (item) =>
            item.product.id == directProduct.id &&
            item.scannedWeightCode == null &&
            item.kotProductReferences.isEmpty,
      );
      return QrAddResult.success(item);
    }

    if (!RegExp(r'^\d{9}$').hasMatch(value)) {
      return QrAddResult.failure('Product code $value was not found.');
    }

    final qrProductId = value.substring(0, 4);
    final weightCode = value.substring(5, 9);
    final weightGrams = int.parse(weightCode);
    if (weightGrams <= 0) {
      return QrAddResult.failure('The QR code weight must be greater than 0.');
    }

    final product = products.firstWhereOrNull(
      (product) => _matchesQrProductId(product, qrProductId),
    );
    if (product == null) {
      return QrAddResult.failure('Product ID $qrProductId was not found.');
    }
    final index = cart.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.scannedWeightCode == weightCode &&
          item.kotProductReferences.isEmpty,
    );
    if (index >= 0) {
      cart[index].quantity++;
      cart.refresh();
      _queueOrderTotalsSync();
      return QrAddResult.success(cart[index]);
    }

    final item = CartItem(product: product, scannedWeightCode: weightCode);
    cart.add(item);
    _queueOrderTotalsSync();
    return QrAddResult.success(item);
  }

  bool _matchesQrProductId(Product product, String qrProductId) {
    final storedId = product.productId.trim().isEmpty
        ? '${product.id}'
        : product.productId.trim();
    final numericStoredId = int.tryParse(storedId);
    final numericQrProductId = int.tryParse(qrProductId);
    return numericStoredId == null
        ? storedId.toLowerCase() == qrProductId.toLowerCase()
        : numericQrProductId != null && numericStoredId == numericQrProductId;
  }

  void increment(CartItem item) {
    if (item.effectiveWeightKg != null) {
      item.manualWeightKg = double.parse(
        (item.editableAmount + 0.1).toStringAsFixed(3),
      );
      item.quantity = 1;
      cart.refresh();
      _queueOrderTotalsSync();
      return;
    }
    item.quantity++;
    cart.refresh();
    _queueOrderTotalsSync();
  }

  void updateItemNotes(CartItem item, String value) {
    item.notes = value;
  }

  Future<bool> decrement(CartItem item) async {
    removeKotQuantityError.value = null;
    _decrementLocal(item);
    log(
      'Decremented product ${item.product.id} in local state only.',
      name: 'RemoveKotQuantityController',
    );
    return true;
  }

  void _decrementLocal(CartItem item, {bool syncTotals = true}) {
    if (item.effectiveWeightKg != null) {
      final updatedWeight = item.editableAmount - 0.1;
      if (updatedWeight <= 0) {
        kitchenSelectedItems.remove(item);
        cart.remove(item);
      } else {
        item.manualWeightKg = double.parse(updatedWeight.toStringAsFixed(3));
        item.quantity = 1;
        cart.refresh();
      }
    } else if (item.quantity == 1) {
      kitchenSelectedItems.remove(item);
      cart.remove(item);
    } else {
      item.quantity--;
      cart.refresh();
    }
    if (syncTotals) _queueOrderTotalsSync();
  }

  void remove(CartItem item) {
    _markSentKitchenItemChanged(item);
    kitchenSelectedItems.remove(item);
    cart.remove(item);
    _queueOrderTotalsSync();
  }

  Future<bool> removeKotProduct(CartItem item) async {
    if (isRemovingKotProduct.value) return false;

    removeKotProductError.value = null;

    // Products that have not been sent to the kitchen do not have a backend
    // detail row yet, so removing them remains a local-only operation.
    if (item.kotProductReferences.isEmpty) {
      _removeKotProductLocally(item);
      return true;
    }

    final references = item.kotProductReferences
        .where((reference) => reference.detailId != null)
        .toList(growable: false);
    if (references.length != item.kotProductReferences.length) {
      removeKotProductError.value =
          'The saved product detail is unavailable. Refresh the KOT and try again.';
      return false;
    }

    final useCase = _removeKotProductUseCase;
    if (useCase == null) {
      removeKotProductError.value =
          'Kitchen product removal service is unavailable.';
      return false;
    }

    isRemovingKotProduct.value = true;
    try {
      // A cart line can contain rows from more than one KOT submission. Remove
      // every saved detail row before clearing the combined local cart line.
      for (final reference in references) {
        final response = await useCase(
          RemoveKotProductRequest(
            orderId: reference.orderId,
            detailId: reference.detailId!,
          ),
        );
        if (response.status == false) {
          removeKotProductError.value =
              response.message ?? 'Unable to remove the product.';
          return false;
        }
        item.kotProductReferences.remove(reference);
      }

      _removeKotProductLocally(item);
      log(
        'Removed product ${item.product.id} from the backend KOT and local state.',
        name: 'RemoveKotProductController',
      );
      return true;
    } on DioException catch (error) {
      removeKotProductError.value = _saveOrderApiError(error);
      return false;
    } catch (error, stackTrace) {
      removeKotProductError.value =
          'Unable to remove the product. Please try again.';
      log(
        'Unexpected KOT product-removal error',
        name: 'RemoveKotProductController',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      isRemovingKotProduct.value = false;
    }
  }

  void _removeKotProductLocally(CartItem item) {
    kitchenSelectedItems.remove(item);
    cart.remove(item);
    _queueOrderTotalsSync();
  }

  String? setItemAmount(CartItem item, double amount) {
    final isWholeNumber = amount == amount.roundToDouble();
    if (!_usesKilogramWeight(item) && !isWholeNumber) {
      final unit = item.apiUnit.isEmpty ? 'pcs' : item.apiUnit;
      return 'Enter a whole-number quantity for $unit.';
    }
    final oldKey = item.uniqueId;
    final oldQuantity = item.quantity;
    if (!_usesKilogramWeight(item)) {
      item.quantity = amount.toInt();
      item.manualWeightKg = null;
      if (item.quantity < oldQuantity) {
        _capSentKitchenQuantity(item, item.quantity, key: oldKey);
      }
    } else {
      _markSentKitchenItemChanged(item, key: oldKey);
      item.quantity = 1;
      item.manualWeightKg = amount;
    }
    cart.refresh();
    _queueOrderTotalsSync();
    return null;
  }

  void _markSentKitchenItemChanged(CartItem item, {String? key}) {
    final tableId = activeTableNumber.value;
    if (tableId == null) return;
    final sentQuantities = _kitchenSentQuantities[tableId];
    final itemKey = key ?? item.uniqueId;
    if ((sentQuantities?[itemKey] ?? 0) <= 0) return;
    sentQuantities!.remove(itemKey);
    _kotOrdersNeedingReconciliation.add(tableId);
  }

  void _capSentKitchenQuantity(CartItem item, int quantity, {String? key}) {
    final tableId = activeTableNumber.value;
    if (tableId == null) return;
    final sentQuantities = _kitchenSentQuantities[tableId];
    final itemKey = key ?? item.uniqueId;
    final sent = sentQuantities?[itemKey] ?? 0;
    if (sent <= quantity) return;
    sentQuantities![itemKey] = quantity;
    _kotOrdersNeedingReconciliation.add(tableId);
  }

  bool _usesKilogramWeight(CartItem item) {
    return _isKilogramUnit(item.apiUnit);
  }

  static bool _isKilogramUnit(String? value) {
    final unit = value?.trim().toLowerCase() ?? '';
    return unit == 'kg' || unit.contains('kilo');
  }

  void clearCart() {
    kitchenSelectedItems.clear();
    cart.clear();
    _queueOrderTotalsSync();
  }

  void startNewBill() {
    kitchenSelectedItems.clear();
    cart.clear();
    paymentMethod.value = paymentMethods.first;
    saveOrderError.value = null;
    kotOrderError.value = null;
    lastKotOrder.value = null;
    completeKotOrderError.value = null;
    completedKotOrder.value = null;
    _completedKotCartSnapshot.clear();
    holdOrderError.value = null;
    resumeOrderError.value = null;
    deleteHeldBillError.value = null;
    takeAwayHoldError.value = null;
    takeAwayCustomerName.value = '';
    takeAwayCustomerPhone.value = '';
    isCustomerDetailsPrompted.value = false;
    takeAwayHoldOrderId.value = null;
    takeAwaySaveOrderError.value = null;
    isTakeAwayOrderCompleted.value = false;
    takeAwayProcessingOrders.clear();
    takeAwayProcessingError.value = null;
    searchController.clear();
    searchQuery.value = '';
    _clearAdjustments();
    _resetBackendTotals();
    log('Started a new bill.', name: 'NewBill');
  }

  HeldBill holdCurrentBill({
    int? id,
    double? subtotal,
    double gst = 0,
    double? total,
  }) {
    final bill = HeldBill(
      id: id ?? _nextBillId++,
      createdAt: DateTime.now(),
      items: cart.map((item) => item.copy()).toList(),
      gst: gst,
      discountType: discountType.value,
      discountValue: discountValue.value,
      discountAmount: discountAmount,
      discountOffer: discountOffer.value,
      discountReason: discountReason.value,
      charge: chargeAmount.value,
      chargeReason: chargeReason.value,
      backendSubtotal: subtotal,
      backendTotal: total,
    );
    heldBills.insert(0, bill);
    cart.clear();
    _clearAdjustments();
    _resetBackendTotals();
    return bill;
  }

  void restoreHeldBill(HeldBill bill) {
    cart.assignAll(bill.items.map((item) => item.copy()));
    heldBills.remove(bill);
    backendSubtotal.value = bill.subtotal;
    backendGst.value = bill.gst;
    backendTotal.value = bill.total;
    discountType.value = bill.discountType;
    discountValue.value = bill.discountValue;
    discountOffer.value = bill.discountOffer;
    discountReason.value = bill.discountReason;
    chargeAmount.value = bill.charge;
    chargeReason.value = bill.chargeReason;
  }

  void _resetBackendTotals() {
    _cancelTotalsSync();
    backendSubtotal.value = null;
    backendGst.value = null;
    backendTotal.value = null;
    savedOrderNumber.value = null;
  }

  void refreshOrderTotals() {
    _queueOrderTotalsSync(delay: Duration.zero);
  }

  void _queueOrderTotalsSync({
    Duration delay = const Duration(milliseconds: 250),
  }) {
    _syncActiveTableOrder();
    _resetBackendTotals();
    if (flow.value != PosFlow.billing) return;
    final useCase = _saveOrderUseCase;
    final staffId = _selectedStaffId;
    if (useCase == null || staffId == null || cart.isEmpty) return;

    final revision = _totalsSyncRevision;
    final request = _saveOrderRequest(staffId);
    _totalsSyncTimer = Timer(
      delay,
      () => unawaited(_syncOrderTotals(useCase, request, revision)),
    );
  }

  Future<void> _syncOrderTotals(
    SaveOrderUseCase useCase,
    SaveOrderRequest request,
    int revision,
  ) async {
    isSyncingTotals.value = true;
    try {
      final response = await useCase(request);
      if (revision != _totalsSyncRevision) return;
      if (response.status == false) {
        log(
          response.message ?? 'Unable to refresh order totals.',
          name: 'OrderTotals',
        );
        return;
      }

      final order = response.data?.order;
      backendSubtotal.value = order?.subtotal;
      backendGst.value = order?.gst ?? 0;
      backendTotal.value = order?.total ?? subtotal;
    } on DioException catch (error) {
      if (revision == _totalsSyncRevision) {
        log(_saveOrderApiError(error), name: 'OrderTotals', error: error);
      }
    } catch (error, stackTrace) {
      if (revision == _totalsSyncRevision) {
        log(
          'Unable to refresh order totals.',
          name: 'OrderTotals',
          error: error,
          stackTrace: stackTrace,
        );
      }
    } finally {
      if (revision == _totalsSyncRevision) {
        isSyncingTotals.value = false;
      }
    }
  }

  SaveOrderRequest _saveOrderRequest(int staffId) {
    return SaveOrderRequest(
      staffId: staffId,
      discountType: discountType.value,
      discountValue: discountValue.value,
      offer: discountOffer.value,
      discountReason: discountReason.value,
      charge: chargeAmount.value,
      chargeReason: chargeReason.value,
      paymentMode: paymentMethod.value,
      products: cart
          .map(
            (item) => SaveOrderProductRequest(
              productId: item.product.id,
              quantity: item.orderQuantity,
              unitValue: item.apiUnitValue,
              unit: item.apiUnit,
            ),
          )
          .toList(),
    );
  }

  int? get _selectedStaffId {
    if (!Get.isRegistered<StaffController>()) return null;
    return Get.find<StaffController>().selectedStaff.value?.id;
  }

  void _useKotTableStaff({required int? staffId, required String? staffName}) {
    if (!Get.isRegistered<StaffController>()) return;
    final normalizedName = staffName?.trim();
    final controller = Get.find<StaffController>();
    final selectedStaff = controller.selectedStaff.value;
    final selectedName = selectedStaff?.name?.trim();
    final selectedStaffMatches =
        selectedStaff != null &&
        ((staffId != null && selectedStaff.id == staffId) ||
            (normalizedName?.isNotEmpty == true &&
                selectedName?.toLowerCase() == normalizedName!.toLowerCase()));
    final matchingStaff = selectedStaffMatches
        ? selectedStaff
        : controller.staff.firstWhereOrNull(
            (staff) =>
                (staffId != null && staff.id == staffId) ||
                (normalizedName?.isNotEmpty == true &&
                    staff.name?.trim().toLowerCase() ==
                        normalizedName!.toLowerCase()),
          );
    controller.selectTemporaryStaff(
      matchingStaff ??
          StaffData(
            id: staffId,
            name: normalizedName?.isNotEmpty == true ? normalizedName : 'Staff',
          ),
    );
  }

  void _restoreStaffAfterKotTable() {
    if (!Get.isRegistered<StaffController>()) return;
    Get.find<StaffController>().restoreStaffBeforeTemporarySelection();
  }

  void _updateActiveKotTableStaff(StaffData? staff) {
    if (staff == null ||
        flow.value != PosFlow.kot ||
        kotStage.value != KotStage.order) {
      return;
    }
    final tableNumber = activeTableNumber.value;
    if (tableNumber == null) return;
    final order = tableOrders[tableNumber];
    if (order == null) return;
    tableOrders[tableNumber] = order.copyWithStaff(staff);
  }

  void _cancelTotalsSync() {
    _totalsSyncTimer?.cancel();
    _totalsSyncTimer = null;
    _totalsSyncRevision++;
    isSyncingTotals.value = false;
  }

  void _clearAdjustments() {
    discountType.value = 'none';
    discountValue.value = 0;
    discountOffer.value = '';
    discountReason.value = '';
    chargeAmount.value = 0;
    chargeReason.value = '';
  }

  @override
  void onClose() {
    _staffSelectionWorker?.dispose();
    _staffSelectionWorker = null;
    _restoreStaffAfterKotTable();
    _cancelTotalsSync();
    _tableStatusSyncTimer?.cancel();
    _tableStatusSyncTimer = null;
    searchController.dispose();
    super.onClose();
  }
}
