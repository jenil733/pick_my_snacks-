import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appimages.dart';
import 'package:pick_my_snacks/src/data/model/get_product.dart' as api_model;
import 'package:pick_my_snacks/src/data/model/get_hold.dart';
import 'package:pick_my_snacks/src/data/model/get_resume.dart';
import 'package:pick_my_snacks/src/data/model/hold_order.dart';
import 'package:pick_my_snacks/src/data/model/save_order.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_products_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/delete_held_bill_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_hold_orders_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/hold_order_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/resume_order_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_order_usecase.dart';
import 'package:pick_my_snacks/src/presentation/controller/staff/staff_controller.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.image,
    this.productId = '',
  });

  final int id;
  final String name;
  final String unit;
  final double price;
  final String image;
  final String productId;
}

class CartItem {
  CartItem({required this.product, this.quantity = 1, this.scannedWeightCode});

  final Product product;
  int quantity;
  final String? scannedWeightCode;

  int? get scannedWeightGrams =>
      scannedWeightCode == null ? null : int.tryParse(scannedWeightCode!);

  String get displayUnit {
    final code = scannedWeightCode;
    if (code == null || code.length != 4) return product.unit;
    return '${code.substring(0, 1)}.${code.substring(1)}';
  }

  double get total {
    final weight = scannedWeightGrams;
    final unitAmount = weight == null
        ? product.price
        : product.price * weight / 1000;
    return unitAmount * quantity;
  }

  CartItem copy() => CartItem(
    product: product,
    quantity: quantity,
    scannedWeightCode: scannedWeightCode,
  );
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

class HomeController extends GetxController {
  HomeController([
    this._getProductsUseCase,
    this._saveOrderUseCase,
    this._holdOrderUseCase,
    this._getHoldOrdersUseCase,
    this._resumeOrderUseCase,
    this._deleteHeldBillUseCase,
  ]);

  final GetProductsUseCase? _getProductsUseCase;
  final SaveOrderUseCase? _saveOrderUseCase;
  final HoldOrderUseCase? _holdOrderUseCase;
  final GetHoldOrdersUseCase? _getHoldOrdersUseCase;
  final ResumeOrderUseCase? _resumeOrderUseCase;
  final DeleteHeldBillUseCase? _deleteHeldBillUseCase;

  final searchController = TextEditingController();
  final searchQuery = ''.obs;
  final cart = <CartItem>[].obs;
  final heldBills = <HeldBill>[].obs;
  final heldOrderSummaries = <HeldOrderSummary>[].obs;
  final products = <Product>[].obs;
  final isLoadingProducts = false.obs;
  final productError = RxnString();
  final paymentMethod = 'cash'.obs;
  final isSavingOrder = false.obs;
  final isSyncingTotals = false.obs;
  final saveOrderError = RxnString();
  final savedOrderNumber = RxnString();
  final isHoldingOrder = false.obs;
  final holdOrderError = RxnString();
  final isLoadingHeldOrders = false.obs;
  final heldOrdersError = RxnString();
  final resumingOrderId = RxnInt();
  final resumeOrderError = RxnString();
  final deletingOrderId = RxnInt();
  final deleteHeldBillError = RxnString();
  final backendSubtotal = RxnDouble();
  final backendGst = RxnDouble();
  final backendTotal = RxnDouble();
  final discountType = 'none'.obs;
  final discountValue = 0.0.obs;
  final discountOffer = ''.obs;
  final discountReason = ''.obs;
  final chargeAmount = 0.0.obs;
  final chargeReason = ''.obs;
  int _nextBillId = 1;
  Timer? _totalsSyncTimer;
  Worker? _staffSelectionWorker;
  int _totalsSyncRevision = 0;
  final Set<int> _resumedHeldOrderIds = <int>{};

  static const paymentMethods = <String>['cash', 'credit', 'card', 'upi'];

  int get heldBillCount => heldOrderSummaries.isNotEmpty
      ? heldOrderSummaries.length
      : heldBills.length;

  static const _previewProducts = <Product>[
    Product(
      id: 1,
      name: 'Bisleri Water Bottle',
      unit: '1L',
      price: 20,
      image: AppImages.water,
    ),
    Product(
      id: 2,
      name: 'Coca Cola',
      unit: '500ml',
      price: 40,
      image: AppImages.cola,
    ),
    Product(
      id: 3,
      name: "Lay's Classic",
      unit: '52g',
      price: 20,
      image: AppImages.chips,
    ),
    Product(
      id: 4,
      name: 'Parle-G Biscuit',
      unit: '100g',
      price: 10,
      image: AppImages.biscuit,
    ),
    Product(
      id: 5,
      name: 'Dairy Milk Chocolate',
      unit: '50g',
      price: 30,
      image: AppImages.chocolate,
    ),
    Product(
      id: 6,
      name: 'Surf Excel',
      unit: '1kg',
      price: 145,
      image: AppImages.detergent,
    ),
    Product(
      id: 7,
      name: 'Colgate Toothpaste',
      unit: '100g',
      price: 45,
      image: AppImages.toothpaste,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<StaffController>()) {
      _staffSelectionWorker = ever(
        Get.find<StaffController>().selectedStaff,
        (_) => refreshOrderTotals(),
      );
    }
    if (_getProductsUseCase == null) {
      _loadPreviewData();
      return;
    }
    getProducts();
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
                  quantity: item.quantity,
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
              order.id == null || !_resumedHeldOrderIds.contains(order.id),
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

      cart.assignAll(
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
          return CartItem(
            product: product,
            quantity: item.qty ?? item.quantity ?? 1,
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
      (item) => item.product.id == product.id && item.scannedWeightCode == null,
    );
    if (index < 0) {
      cart.add(CartItem(product: product));
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
            item.scannedWeightCode == null,
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
          item.product.id == product.id && item.scannedWeightCode == weightCode,
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
    item.quantity++;
    cart.refresh();
    _queueOrderTotalsSync();
  }

  void decrement(CartItem item) {
    if (item.quantity == 1) {
      cart.remove(item);
    } else {
      item.quantity--;
      cart.refresh();
    }
    _queueOrderTotalsSync();
  }

  void remove(CartItem item) {
    cart.remove(item);
    _queueOrderTotalsSync();
  }

  void clearCart() {
    cart.clear();
    _queueOrderTotalsSync();
  }

  void startNewBill() {
    cart.clear();
    paymentMethod.value = paymentMethods.first;
    saveOrderError.value = null;
    holdOrderError.value = null;
    resumeOrderError.value = null;
    deleteHeldBillError.value = null;
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
    _resetBackendTotals();
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
              quantity: item.quantity,
            ),
          )
          .toList(),
    );
  }

  int? get _selectedStaffId {
    if (!Get.isRegistered<StaffController>()) return null;
    return Get.find<StaffController>().selectedStaff.value?.id;
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
    _cancelTotalsSync();
    _staffSelectionWorker?.dispose();
    searchController.dispose();
    super.onClose();
  }
}
