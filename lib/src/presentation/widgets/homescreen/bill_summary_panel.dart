import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/app_toast.dart';
import 'package:pick_my_snacks/src/core/utils/helper/texthelper.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/staff/staff_controller.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/bill_adjustment_dialogs.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/common_widgets.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/payment_method_dropdown.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/take_away_orders_panel.dart';
import 'package:pick_my_snacks/src/printing/kitchen_printer.dart';
import 'package:pick_my_snacks/src/printing/printer_manager.dart';
import 'package:pick_my_snacks/src/printing/printer_settings_model.dart';
import 'package:pick_my_snacks/src/services/receipt_printer_service.dart';

class BillSummaryPanel extends StatelessWidget {
  const BillSummaryPanel({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: Column(
        children: [
          SectionHeader(
            title: 'Bill Summary',
            trailing: BillAdjustmentButtons(controller: controller),
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(
              () => ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  _totalsCard(),
                  const SizedBox(height: 12),
                  _totalAmountStrip(),
                  const SizedBox(height: 12),
                  PaymentMethodDropdown(controller: controller),
                  const SizedBox(height: 18),
                  Text('Items in Bill', style: TextHelper.bodySemiBold),
                  const SizedBox(height: 8),
                  if (controller.cart.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 42,
                            color: AppColors.divider,
                          ),
                          const SizedBox(height: 9),
                          Text('No items added', style: TextHelper.caption),
                        ],
                      ),
                    )
                  else
                    ...controller.cart.map(
                      (item) => _billItemRow(context, item),
                    ),
                  const Divider(height: 24),
                ],
              ),
            ),
          ),
          Obx(
            () => Padding(
              padding: const EdgeInsets.all(14),
              child: controller.flow.value == PosFlow.kot
                  ? _kotActions(context)
                  : controller.flow.value == PosFlow.takeAway
                  ? _takeAwayActions(context)
                  : _billingActions(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _billingActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    controller.cart.isEmpty || controller.isHoldingOrder.value
                    ? null
                    : () => holdBill(context, controller),
                icon: const Icon(Icons.pause_circle_outline_rounded, size: 18),
                label: Text(
                  controller.isHoldingOrder.value ? 'Holding...' : 'Hold Bill',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    controller.cart.isEmpty || controller.isSavingOrder.value
                    ? null
                    : () => printDuplicateBill(context, controller),
                icon: const Icon(Icons.copy_all_rounded, size: 18),
                label: const Text('Copy Bill'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: controller.cart.isEmpty || controller.isSavingOrder.value
                ? null
                : () => printReceipt(context, controller),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              disabledBackgroundColor: AppColors.divider,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: Row(
              children: [
                Text(
                  controller.isSavingOrder.value
                      ? 'Saving Order...'
                      : 'Print Receipt',
                  style: TextHelper.whiteButton,
                ),
                const Spacer(),
                Text(money(controller.total), style: TextHelper.whiteButton),
                const SizedBox(width: 8),
                const Icon(Icons.print_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _takeAwayActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showTakeAwayOrdersPanel(
                  context,
                  controller,
                  initialTab: TakeAwayOrdersTab.pending,
                ),
                icon: const Icon(Icons.pending_actions_rounded),
                label: const Text('Pending'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showTakeAwayOrdersPanel(
                  context,
                  controller,
                  initialTab: TakeAwayOrdersTab.completed,
                ),
                icon: const Icon(Icons.task_alt_rounded),
                label: const Text('Completed'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: controller.cart.isEmpty
                    ? null
                    : () => printTakeAwayBill(
                        context,
                        controller,
                        role: PrinterRole.kitchen,
                      ),
                icon: const Icon(Icons.soup_kitchen_outlined, size: 19),
                label: const Text('Kitchen Bill'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  disabledBackgroundColor: AppColors.divider,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    controller.cart.isEmpty ||
                        controller.isSavingTakeAwayOrder.value
                    ? null
                    : () => completeTakeAway(context, controller),
                icon: const Icon(Icons.takeout_dining_rounded, size: 19),
                label: Text(
                  controller.isSavingTakeAwayOrder.value
                      ? 'Closing...'
                      : controller.takeAwayHoldOrderId.value != null
                      ? 'Close Order'
                      : 'Take Away',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  disabledBackgroundColor: AppColors.divider,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kotActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed:
                controller.cart.isEmpty ||
                    controller.isSavingKotOrder.value ||
                    controller.isCompletingKotOrder.value
                ? null
                : () => holdKotTable(context, controller),
            icon: const Icon(Icons.table_restaurant_outlined, size: 19),
            label: Text(
              controller.isSavingKotOrder.value ? 'Holding...' : 'Hold Table',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    (!controller.hasKitchenOrderAwaitingPrint &&
                            !controller.hasSelectedPendingKitchenItems) ||
                        controller.isSavingKotOrder.value
                    ? null
                    : () => printKitchen(context, controller),
                icon: const Icon(Icons.soup_kitchen_outlined, size: 19),
                label: Text(
                  controller.isSavingKotOrder.value
                      ? 'Printing...'
                      : 'Kitchen Bill',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    controller.cart.isEmpty ||
                        controller.isSavingOrder.value ||
                        controller.isSavingKotOrder.value ||
                        controller.isCompletingKotOrder.value ||
                        controller.isRemovingKotProduct.value ||
                        controller.isRemovingKotQuantity.value
                    ? null
                    : () => closeKotBill(context, controller),
                icon: const Icon(Icons.receipt_long_rounded, size: 19),
                label: Text(
                  controller.isSavingKotOrder.value ||
                          controller.isCompletingKotOrder.value
                      ? 'Closing...'
                      : 'Close Bill',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _totalsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _summaryRow(
            label: 'Items (${controller.cart.length})',
            value: money(controller.subtotal),
          ),
          if (controller.discountType.value != 'none')
            _summaryRow(
              label: 'Discount',
              value: '- ${money(controller.discountAmount)}',
              valueColor: AppColors.success,
            ),
          _summaryRow(label: 'GST', value: money(controller.tax)),
          if (controller.chargeAmount.value > 0)
            _summaryRow(
              label: 'Charge',
              value: '+ ${money(controller.chargeAmount.value)}',
              valueColor: AppColors.warning,
            ),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required String label,
    required String value,
    Widget? trailing,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: TextHelper.body),
          if (trailing != null) ...[const SizedBox(width: 6), trailing],
          const Spacer(),
          Text(
            value,
            style: TextHelper.bodySemiBold.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _totalAmountStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text('Total Amount', style: TextHelper.totalAmount),
          const Spacer(),
          Text(money(controller.total), style: TextHelper.totalAmountValue),
        ],
      ),
    );
  }

  Widget _billItemRow(BuildContext context, CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (controller.flow.value == PosFlow.takeAway) ...[
            Tooltip(
              message: 'Include ${item.product.name} in Kitchen Bill',
              child: Checkbox(
                value: controller.isKitchenItemSelected(item),
                onChanged: (value) =>
                    controller.setKitchenItemSelected(item, value ?? false),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              item.product.name,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextHelper.captionText,
            ),
          ),
          const SizedBox(width: 6),
          BillQuantityControl(controller: controller, item: item),
          const SizedBox(width: 6),
          SizedBox(
            width: 62,
            child: Column(
              children: [
                IconButton(
                  tooltip: 'Delete ${item.product.name}',
                  onPressed:
                      controller.isRemovingKotProduct.value ||
                          controller.isRemovingKotQuantity.value
                      ? null
                      : () => _deleteBillItem(context, item),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 30,
                  ),
                  padding: EdgeInsets.zero,
                  color: AppColors.delete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                ),
                const SizedBox(height: 3),
                Text(
                  money(item.total),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextHelper.captionText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBillItem(BuildContext context, CartItem item) async {
    final removed = await controller.removeKotProduct(item);
    if (!context.mounted) return;
    if (!removed) {
      AppToast.error(
        context,
        controller.removeKotProductError.value ??
            'Unable to remove the product.',
      );
      return;
    }
    AppToast.show(context, '${item.product.name} was removed from the bill.');
  }
}

class BillQuantityControl extends StatelessWidget {
  const BillQuantityControl({
    required this.controller,
    required this.item,
    super.key,
  });

  final HomeController controller;
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(
            tooltip: 'Decrease ${item.product.name}',
            icon: Icons.remove_rounded,
            onPressed: () => controller.decrement(item),
          ),
          EditableItemAmount(controller: controller, item: item, width: 36),
          _button(
            tooltip: 'Increase ${item.product.name}',
            icon: Icons.add_rounded,
            onPressed: () => controller.increment(item),
          ),
        ],
      ),
    );
  }

  Widget _button({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 27, height: 28),
      icon: Icon(icon, size: 16),
    );
  }
}

Future<void> holdBill(BuildContext context, HomeController controller) async {
  if (controller.cart.isEmpty) return;
  final hasCustomerDetails = await _requireCustomerDetails(context, controller);
  if (!hasCustomerDetails || !context.mounted) return;
  final staffController = Get.isRegistered<StaffController>()
      ? Get.find<StaffController>()
      : null;
  final bill = await controller.holdOrder(
    staffId: staffController?.selectedStaff.value?.id,
  );
  if (!context.mounted) return;
  if (bill == null) {
    _showPrinterToast(
      context,
      controller.holdOrderError.value ?? 'Unable to hold the order.',
    );
    return;
  }
  AppToast.show(context, 'Bill #${bill.id} held successfully.');
}

Future<void> printDuplicateBill(
  BuildContext context,
  HomeController controller,
) async {
  final hasCustomerDetails = await _requireCustomerDetails(context, controller);
  if (!hasCustomerDetails || !context.mounted) return;
  if (controller.savedOrderNumber.value == null) {
    final staffController = Get.isRegistered<StaffController>()
        ? Get.find<StaffController>()
        : null;
    final orderSaved = await controller.saveOrder(
      staffId: staffController?.selectedStaff.value?.id,
    );
    if (!context.mounted) return;
    if (!orderSaved) {
      _showPrinterToast(
        context,
        controller.saveOrderError.value ?? 'Unable to save the order.',
      );
      return;
    }
  }

  final printerService = ReceiptPrinterService();
  try {
    if (Get.isRegistered<PrinterManager>()) {
      await Get.find<PrinterManager>().printDuplicate(
        DuplicatePrintJob(
          items: controller.cart.map((item) => item.copy()).toList(),
          orderNumber: controller.savedOrderNumber.value ?? '',
        ),
      );
      if (!context.mounted) return;
      AppToast.show(context, 'Duplicate bill sent to the billing printer.');
      return;
    }
    if (!await _ensurePrinterReady(context, printerService)) return;
    if (!context.mounted) return;
    await printerService.printBluetoothDuplicateBill(
      items: controller.cart.map((item) => item.copy()).toList(),
      orderNumber: controller.savedOrderNumber.value ?? '',
      paperSize: ReceiptPaperSize.mm58,
    );
    if (!context.mounted) return;
    AppToast.show(context, 'Duplicate bill sent to the printer.');
  } on PrinterManagerException catch (error) {
    if (!context.mounted) return;
    AppToast.dismiss();
    _showPrinterToast(context, error.message);
  } on ReceiptPrinterException catch (error) {
    if (!context.mounted) return;
    AppToast.dismiss();
    _showPrinterToast(context, error.message);
  } catch (_) {
    if (!context.mounted) return;
    AppToast.dismiss();
    _showPrinterToast(context, 'The printer is not connected.');
  }
}

Future<void> printReceipt(
  BuildContext context,
  HomeController controller,
) async {
  final isKotFlow = controller.flow.value == PosFlow.kot;
  final hasCustomerDetails = await _requireCustomerDetails(context, controller);
  if (!hasCustomerDetails || !context.mounted) return;
  final staffController = Get.isRegistered<StaffController>()
      ? Get.find<StaffController>()
      : null;
  final selectedStaffId = staffController?.selectedStaff.value?.id;
  final orderSaved = isKotFlow
      ? controller.completedKotOrder.value != null ||
            await controller.completeKotOrder(staffId: selectedStaffId)
      : await _ensureOrderSaved(controller, selectedStaffId);
  if (!context.mounted) return;
  if (!orderSaved) {
    _showPrinterToast(
      context,
      isKotFlow
          ? controller.completeKotOrderError.value ??
                'Unable to complete the KOT order.'
          : controller.saveOrderError.value ?? 'Unable to save the order.',
    );
    return;
  }

  final completedOrder = controller.completedKotOrder.value?.completedOrder;
  final items = isKotFlow
      ? controller.completedReceiptItems
      : controller.cart.map((item) => item.copy()).toList();
  final subtotal = isKotFlow
      ? completedOrder?.subtotal ?? 0
      : controller.subtotal;
  final tax = isKotFlow ? completedOrder?.gst ?? 0 : controller.tax;
  final discount = isKotFlow
      ? completedOrder?.discount ?? 0
      : controller.discountAmount;
  final charge = isKotFlow
      ? completedOrder?.charge ?? 0
      : controller.chargeAmount.value;
  final total = isKotFlow ? completedOrder?.total ?? 0 : controller.total;
  final paymentMethod = isKotFlow
      ? completedOrder?.paymentMode ?? controller.paymentMethod.value
      : controller.paymentMethod.value;
  final orderNumber = controller.savedOrderNumber.value ?? '';
  final printerService = ReceiptPrinterService();

  try {
    if (Get.isRegistered<PrinterManager>()) {
      try {
        await Get.find<PrinterManager>().printReceipt(
          ReceiptPrintJob(
            items: items,
            subtotal: subtotal,
            tax: tax,
            discount: discount,
            charge: charge,
            total: total,
            paymentMethod: paymentMethod,
            orderNumber: orderNumber,
            customerName: controller.takeAwayCustomerName.value,
            customerPhone: controller.takeAwayCustomerPhone.value,
          ),
        );
        if (context.mounted) {
          AppToast.show(context, 'Receipt sent to the billing printer.');
        }
      } catch (_) {
        if (context.mounted) {
          _showPrinterToast(context, 'Billing printer is offline. Bill closed.');
        }
      }
      if (isKotFlow) {
        controller.finishCompletedKotOrder();
      } else {
        controller.startNewBill();
      }
      return;
    }

    if (await _ensurePrinterReady(context, printerService, showDialogIfDisconnected: false)) {
      if (context.mounted) {
        try {
          await printerService.printBluetoothReceipt(
            items: items,
            subtotal: subtotal,
            tax: tax,
            discount: discount,
            charge: charge,
            total: total,
            paymentMethod: paymentMethod,
            orderNumber: orderNumber,
            paperSize: ReceiptPaperSize.mm58,
            customerName: controller.takeAwayCustomerName.value,
            customerPhone: controller.takeAwayCustomerPhone.value,
          );
          if (context.mounted) {
            AppToast.show(context, 'Receipt sent to the printer.');
          }
        } catch (_) {
          if (context.mounted) {
            _showPrinterToast(context, 'Printer is offline. Bill closed.');
          }
        }
      }
    }
  } catch (_) {
    // Ignore printing errors and close the bill
  }

  if (isKotFlow) {
    controller.finishCompletedKotOrder();
  } else {
    controller.startNewBill();
  }
}

Future<bool> printKitchen(
  BuildContext context,
  HomeController controller, {
  bool selectedOnly = true,
  bool showSuccessToast = true,
}) async {
  final hasCustomerDetails = await _requireCustomerDetails(context, controller);
  if (!hasCustomerDetails || !context.mounted) return false;

  if (!controller.hasKitchenOrderAwaitingPrint) {
    final items = selectedOnly
        ? controller.selectedPendingKitchenItems
        : controller.pendingKitchenItems;
    if (items.isEmpty) {
      if (selectedOnly) {
        _showPrinterToast(context, 'Select at least one new product to print.');
        return false;
      }
      return true;
    }
  }

  final staffController = Get.isRegistered<StaffController>()
      ? Get.find<StaffController>()
      : null;
  final staff = staffController?.selectedStaff.value;
  final orderSaved =
      controller.hasKitchenOrderAwaitingPrint ||
      await controller.saveKitchenOrder(
        staffId: staff?.id,
        selectedOnly: selectedOnly,
      );
  if (!context.mounted) return false;
  if (!orderSaved) {
    _showPrinterToast(
      context,
      controller.kotOrderError.value ?? 'Unable to save the kitchen order.',
    );
    return false;
  }
  if (!Get.isRegistered<PrinterManager>()) {
    _showPrinterToast(
      context,
      'Kitchen Printer is not configured. Order saved.',
    );
    controller.confirmKitchenOrderPrinted();
    return true;
  }

  try {
    await Get.find<PrinterManager>().printKitchen(
      KitchenPrintJob(
        items: controller.lastKitchenOrderItems
            .map((item) => item.copy())
            .toList(),
        orderNumber: controller.savedOrderNumber.value ?? '',
        paperSize: ReceiptPaperSize.mm58,
        tableNumber: controller.activeTableNumber.value?.toString(),
        staffName: staff?.name,
        customerName: controller.takeAwayCustomerName.value,
        customerPhone: controller.takeAwayCustomerPhone.value,
      ),
    );
    if (!context.mounted) return false;
    if (showSuccessToast) {
      AppToast.show(context, 'Kitchen order sent to the kitchen printer.');
    }
    controller.confirmKitchenOrderPrinted();
    return true;
  } on PrinterManagerException catch (error) {
    if (!context.mounted) return false;
    AppToast.dismiss();
    _showPrinterToast(context, '${error.message}. Order saved.');
    controller.confirmKitchenOrderPrinted();
    return true;
  } catch (_) {
    if (!context.mounted) return false;
    AppToast.dismiss();
    _showPrinterToast(context, 'Kitchen Printer is unavailable. Order saved.');
    controller.confirmKitchenOrderPrinted();
    return true;
  }
}

/// Saves a kitchen hold before printing a take-away kitchen bill. The final
/// take-away customer receipt remains a local print until checkout is added.
Future<bool> printTakeAwayBill(
  BuildContext context,
  HomeController controller, {
  required PrinterRole role,
}) async {
  if (controller.cart.isEmpty) return false;

  final hasCustomerDetails = await _requireCustomerDetails(context, controller);
  if (!hasCustomerDetails || !context.mounted) {
    return false;
  }

  final staffController = Get.isRegistered<StaffController>()
      ? Get.find<StaffController>()
      : null;
  var orderNumber =
      'TA-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

  if (role == PrinterRole.kitchen) {
    final saved =
        controller.takeAwayHoldOrderId.value != null ||
        await controller.saveTakeAwayKitchenBill(
          staffId: staffController?.selectedStaff.value?.id,
        );
    if (!context.mounted) return false;
    if (!saved) {
      _showPrinterToast(
        context,
        controller.takeAwayHoldError.value ??
            'Unable to create the take-away kitchen bill.',
      );
      return false;
    }
    orderNumber = controller.savedOrderNumber.value ?? orderNumber;
  } else if (role == PrinterRole.takeAway) {
    orderNumber = controller.savedOrderNumber.value ?? orderNumber;
  }

  var items = role == PrinterRole.kitchen
      ? controller.takeAwayHoldOrderId.value != null &&
                controller.lastKitchenOrderItems.isNotEmpty
            ? controller.lastKitchenOrderItems
                  .map((item) => item.copy())
                  .toList()
            : controller.cart
                  .where(controller.isKitchenItemSelected)
                  .map((item) => item.copy())
                  .toList()
      : controller.cart.map((item) => item.copy()).toList();

  if (items.isEmpty) {
    _showPrinterToast(
      context,
      'Select at least one product for the Kitchen Bill.',
    );
    return false;
  }



  if (!Get.isRegistered<PrinterManager>()) {
    _showPrinterToast(
      context,
      '${role.label} Printer is not configured.',
    );
    return true;
  }

  try {
    final manager = Get.find<PrinterManager>();
    if (role == PrinterRole.kitchen) {
      await manager.printKitchen(
        KitchenPrintJob(
          items: items,
          orderNumber: orderNumber,
          paperSize: ReceiptPaperSize.mm58,
          title: 'KITCHEN BILL',
          staffName: staffController?.selectedStaff.value?.name,
          customerName: controller.takeAwayCustomerName.value,
          customerPhone: controller.takeAwayCustomerPhone.value,
        ),
      );
    } else {
      await manager.printTakeAwayReceipt(
        ReceiptPrintJob(
          items: items,
          subtotal: controller.subtotal,
          tax: controller.tax,
          discount: controller.discountAmount,
          charge: controller.chargeAmount.value,
          total: controller.total,
          paymentMethod: controller.paymentMethod.value,
          orderNumber: orderNumber,
          showRate: false,
          customerName: controller.takeAwayCustomerName.value,
          customerPhone: controller.takeAwayCustomerPhone.value,
        ),
      );
    }
    if (!context.mounted) return false;
    AppToast.show(context, '${role.label} printed.');
    return true;
  } on PrinterManagerException catch (error) {
    if (!context.mounted) return false;
    AppToast.dismiss();
    _showPrinterToast(context, '${error.message}. Bill completed.');
    return true;
  } catch (_) {
    if (!context.mounted) return false;
    AppToast.dismiss();
    _showPrinterToast(context, '${role.label} Printer is unavailable. Bill completed.');
    return true;
  }
}

Future<bool> _requireCustomerDetails(
  BuildContext context,
  HomeController controller,
) async {
  final isRequired = controller.flow.value == PosFlow.takeAway;
  if (!isRequired && controller.isCustomerDetailsPrompted.value) {
    return true;
  }
  if (controller.takeAwayCustomerName.value.trim().isNotEmpty &&
      controller.takeAwayCustomerPhone.value.trim().isNotEmpty) {
    if (!isRequired) {
      controller.isCustomerDetailsPrompted.value = true;
    }
    return true;
  }
  if (!isRequired &&
      (controller.takeAwayCustomerName.value.trim().isNotEmpty ||
       controller.takeAwayCustomerPhone.value.trim().isNotEmpty)) {
    controller.isCustomerDetailsPrompted.value = true;
    return true;
  }

  final details = await showDialog<_TakeAwayCustomerDetails>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _TakeAwayCustomerDialog(
      initialName: controller.takeAwayCustomerName.value,
      initialPhone: controller.takeAwayCustomerPhone.value,
      isRequired: isRequired,
    ),
  );
  if (details == null) return false;
  controller.takeAwayCustomerName.value = details.name;
  controller.takeAwayCustomerPhone.value = details.phone;
  if (!isRequired) {
    controller.isCustomerDetailsPrompted.value = true;
  }
  return true;
}

class _TakeAwayCustomerDetails {
  const _TakeAwayCustomerDetails({required this.name, required this.phone});

  final String name;
  final String phone;
}

class _TakeAwayCustomerDialog extends StatefulWidget {
  const _TakeAwayCustomerDialog({
    required this.initialName,
    required this.initialPhone,
    required this.isRequired,
  });

  final String initialName;
  final String initialPhone;
  final bool isRequired;

  @override
  State<_TakeAwayCustomerDialog> createState() =>
      _TakeAwayCustomerDialogState();
}

class _TakeAwayCustomerDialogState extends State<_TakeAwayCustomerDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _nameError = false;
  bool _phoneError = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('Customer details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              onChanged: (_) {
                if (_nameError) {
                  setState(() => _nameError = false);
                }
              },
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: widget.isRequired ? 'Customer name *' : 'Customer name',
                border: const OutlineInputBorder(),
                errorText: _nameError ? 'Customer name is required.' : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              onChanged: (_) {
                if (_phoneError) {
                  setState(() => _phoneError = false);
                }
              },
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: widget.isRequired ? 'Phone number *' : 'Phone number',
                border: const OutlineInputBorder(),
                errorText: _phoneError ? 'Phone number is required.' : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.yellowDark),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.text,
          ),
          onPressed: _submit,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (widget.isRequired && (name.isEmpty || phone.isEmpty)) {
      setState(() {
        _nameError = name.isEmpty;
        _phoneError = phone.isEmpty;
      });
      return;
    }
    Navigator.of(
      context,
    ).pop(_TakeAwayCustomerDetails(name: name, phone: phone));
  }
}

Future<void> completeTakeAway(
  BuildContext context,
  HomeController controller,
) async {
  final completed = await controller.completeTakeAwayOrder();
  if (!context.mounted) return;
  if (!completed) {
    _showPrinterToast(
      context,
      controller.takeAwaySaveOrderError.value ??
          'Unable to complete the take-away order.',
    );
    return;
  }
  
  await printTakeAwayBill(
    context,
    controller,
    role: PrinterRole.takeAway,
  );
  
  if (context.mounted) {
    controller.startNewBill();
  }
}

Future<void> closeKotBill(
  BuildContext context,
  HomeController controller,
) async {
  final hasCustomerDetails = await _requireCustomerDetails(context, controller);
  if (!hasCustomerDetails || !context.mounted) return;

  if (controller.isRemovingKotProduct.value ||
      controller.isRemovingKotQuantity.value) {
    _showPrinterToast(
      context,
      'Wait for the product update to finish before closing the bill.',
    );
    return;
  }
  final staffController = Get.isRegistered<StaffController>()
      ? Get.find<StaffController>()
      : null;
  final reconciled = await controller.reconcileEditedKotOrder(
    staffId: staffController?.selectedStaff.value?.id,
  );
  if (!context.mounted) return;
  if (!reconciled) {
    _showPrinterToast(
      context,
      controller.kotOrderError.value ?? 'Unable to update the table order.',
    );
    return;
  }
  if (controller.pendingKitchenItems.isNotEmpty) {
    final orderSaved = await controller.saveKitchenOrder(
      staffId: staffController?.selectedStaff.value?.id,
      prepareForKitchenPrint: false,
    );
    if (!context.mounted) return;
    if (!orderSaved) {
      _showPrinterToast(
        context,
        controller.kotOrderError.value ?? 'Unable to save the table order.',
      );
      return;
    }
  }
  await printReceipt(context, controller);
}

Future<void> holdKotTable(
  BuildContext context,
  HomeController controller,
) async {
  final hasCustomerDetails = await _requireCustomerDetails(context, controller);
  if (!hasCustomerDetails || !context.mounted) return;

  final staffController = Get.isRegistered<StaffController>()
      ? Get.find<StaffController>()
      : null;
  final tableId = controller.activeTableNumber.value;
  final held = await controller.holdActiveKotTable(
    staffId: staffController?.selectedStaff.value?.id,
  );
  if (!context.mounted) return;
  if (!held) {
    _showPrinterToast(
      context,
      controller.kotOrderError.value ?? 'Unable to hold the table.',
    );
    return;
  }
  AppToast.show(context, 'Table $tableId is now occupied.');
}

void startNewBill(BuildContext context, HomeController controller) {
  if (controller.flow.value == PosFlow.kot) {
    controller.startNewKotBill();
  } else {
    controller.startNewBill();
  }
  AppToast.show(context, 'A new bill has been started.');
}

Future<bool> _ensureOrderSaved(HomeController controller, int? staffId) async {
  if (controller.savedOrderNumber.value?.trim().isNotEmpty == true) {
    return true;
  }
  return controller.saveOrder(staffId: staffId);
}

Future<bool> _ensurePrinterReady(
  BuildContext context,
  ReceiptPrinterService printerService, {
  bool showDialogIfDisconnected = true,
}) async {
  // The Android plugin does not complete connectionStatus when permission is
  // denied, so permission must always be checked before connection status.
  final hasPermission = await printerService.isBluetoothPermissionGranted;
  final needsConnection = !hasPermission || !await printerService.isConnected;
  AppToast.dismiss();
  if (!needsConnection) return true;
  if (!context.mounted) return false;
  if (!showDialogIfDisconnected) return false;

  final connected = await showDialog<bool>(
    context: context,
    builder: (_) => _PrinterConnectionDialog(printerService: printerService),
  );
  return connected == true;
}

void _showPrinterToast(BuildContext context, String message) {
  AppToast.error(context, message);
}

class _PrinterConnectionDialog extends StatefulWidget {
  const _PrinterConnectionDialog({required this.printerService});

  final ReceiptPrinterService printerService;

  @override
  State<_PrinterConnectionDialog> createState() =>
      _PrinterConnectionDialogState();
}

class _PrinterConnectionDialogState extends State<_PrinterConnectionDialog> {
  List<ThermalPrinterDevice> _printers = const [];
  String _message = 'Checking Bluetooth...';
  bool _isLoading = true;
  bool _permissionDenied = false;
  String? _connectingAddress;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
      _message = 'Checking Bluetooth...';
      _printers = const [];
    });

    try {
      var hasPermission =
          await widget.printerService.isBluetoothPermissionGranted;
      if (!hasPermission) {
        hasPermission = await widget.printerService
            .requestBluetoothPermission();
      }
      if (!mounted) return;
      if (!hasPermission) {
        setState(() {
          _isLoading = false;
          _permissionDenied = true;
          _message =
              'Nearby devices permission is required to find and connect '
              'the thermal printer.';
        });
        return;
      }

      final enabled = await widget.printerService.isBluetoothEnabled;
      if (!mounted) return;
      if (!enabled) {
        setState(() {
          _isLoading = false;
          _message = 'Turn on Bluetooth, then tap Refresh.';
        });
        return;
      }

      final printers = await widget.printerService.pairedPrinters;
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _printers = printers;
        _message = printers.isEmpty
            ? 'No paired devices found. Pair the printer in your device '
                  'Bluetooth settings, then tap Refresh.'
            : 'Select your paired thermal printer.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _message = 'Unable to read Bluetooth devices. Tap Refresh to retry.';
      });
    }
  }

  Future<void> _openSettings() async {
    await widget.printerService.openPermissionSettings();
    if (!mounted) return;
    setState(() {
      _message = 'Allow Nearby devices, return here, then tap Refresh.';
    });
  }

  Future<void> _connect(ThermalPrinterDevice printer) async {
    setState(() {
      _connectingAddress = printer.address;
      _message = 'Connecting to ${printer.name}...';
    });

    try {
      final connected = await widget.printerService.connect(printer);
      if (!mounted) return;
      if (connected) {
        Navigator.of(context).pop(true);
        return;
      }

      setState(() {
        _connectingAddress = null;
        _message =
            'Could not connect to ${printer.name}. Make sure it is on and '
            'not connected to another device.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connectingAddress = null;
        _message = 'Connection failed. Check the printer and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnecting = _connectingAddress != null;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.print_rounded),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Connect thermal printer',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The printer is not connected.'),
            const SizedBox(height: 6),
            Text(_message, style: TextHelper.caption),
            if (_isLoading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_printers.isNotEmpty) ...[
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _printers.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final printer = _printers[index];
                    final connecting = _connectingAddress == printer.address;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        child: Icon(Icons.print_outlined),
                      ),
                      title: Text(printer.name),
                      subtitle: Text(printer.address),
                      trailing: connecting
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      enabled: !isConnecting,
                      onTap: () => _connect(printer),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_permissionDenied)
          TextButton.icon(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Open Settings'),
          ),
        TextButton(
          onPressed: isConnecting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton.icon(
          onPressed: _isLoading || isConnecting ? null : _loadPrinters,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ],
    );
  }
}
