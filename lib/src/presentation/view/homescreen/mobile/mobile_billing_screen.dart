import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/app_toast.dart';
import 'package:pick_my_snacks/src/core/utils/helper/texthelper.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/bill_adjustment_dialogs.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/bill_summary_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/common_widgets.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/take_away_orders_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/payment_method_dropdown.dart';

class MobileBillingScreen extends StatelessWidget {
  const MobileBillingScreen({
    required this.controller,
    required this.onAddProduct,
    super.key,
  });

  final HomeController controller;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Bill Summary', style: TextHelper.title),
                    ),
                    BillAdjustmentButtons(controller: controller),
                  ],
                ),
                const SizedBox(height: 12),
                _SummaryCard(controller: controller),
                const SizedBox(height: 12),
                PaymentMethodDropdown(controller: controller),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Items in bill',
                        style: TextHelper.sectionTitle,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: onAddProduct,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.yellowDark,
                        side: const BorderSide(color: AppColors.yellow),
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        minimumSize: const Size(0, 36),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Add Product'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (controller.cart.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 34),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 44,
                          color: AppColors.divider,
                        ),
                        const SizedBox(height: 8),
                        Text('No items added', style: TextHelper.poppins),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: controller.cart
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (controller.flow.value == PosFlow.kot ||
                                      controller.flow.value ==
                                          PosFlow.takeAway) ...[
                                    Tooltip(
                                      message:
                                          controller.flow.value ==
                                              PosFlow.takeAway
                                          ? 'Include ${item.product.name} in Kitchen Bill'
                                          : 'Send ${item.product.name} to kitchen',
                                      child: Checkbox(
                                        value: controller.isKitchenItemSelected(
                                          item,
                                        ),
                                        onChanged: (value) =>
                                            controller.setKitchenItemSelected(
                                              item,
                                              value ?? false,
                                            ),
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
                                      style: TextHelper.body,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  BillQuantityControl(
                                    controller: controller,
                                    item: item,
                                  ),
                                  const SizedBox(width: 6),
                                  SizedBox(
                                    width: 68,
                                    child: Column(
                                      children: [
                                        IconButton(
                                          tooltip:
                                              'Delete ${item.product.name}',
                                          onPressed: () =>
                                              _deleteItem(context, item),
                                          visualDensity: VisualDensity.compact,
                                          constraints:
                                              const BoxConstraints.tightFor(
                                                width: 34,
                                                height: 34,
                                              ),
                                          color: AppColors.delete,
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 19,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          money(item.total),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextHelper.bodySemiBold,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: controller.flow.value == PosFlow.kot
                ? _kotFooter(context)
                : controller.flow.value == PosFlow.takeAway
                ? _takeAwayFooter(context)
                : _billingFooter(context),
          ),
        ],
      ),
    );
  }

  Widget _billingFooter(BuildContext context) {
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
                  controller.isHoldingOrder.value ? 'Holding...' : 'Hold',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.yellowDark,
                  side: const BorderSide(color: AppColors.yellow),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    controller.cart.isEmpty || controller.isSavingOrder.value
                    ? null
                    : () => printDuplicateBill(context, controller),
                icon: const Icon(Icons.copy_all_rounded, size: 18),
                label: const Text('Copy Bill'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.isSavingOrder.value
                        ? 'Saving Order...'
                        : 'Print Receipt',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(money(controller.total)),
                const SizedBox(width: 8),
                const Icon(Icons.print_rounded, size: 19),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _takeAwayFooter(BuildContext context) {
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
            const SizedBox(width: 10),
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
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    controller.cart.isEmpty ||
                        controller.isSavingTakeAwayHold.value ||
                        controller.takeAwayHoldOrderId.value != null
                    ? null
                    : () => sendTakeAwayKotBill(context, controller),
                icon: const Icon(Icons.soup_kitchen_outlined, size: 19),
                label: const Text('Kitchen Bill'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  disabledBackgroundColor: AppColors.divider,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _deleteItem(BuildContext context, CartItem item) async {
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

  Widget _kotFooter(BuildContext context) {
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
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
                    !controller.hasSelectedPendingKitchenItems ||
                        controller.isSavingKotOrder.value
                    ? null
                    : () => sendKotBill(context, controller),
                icon: const Icon(Icons.soup_kitchen_outlined, size: 19),
                label: Text(
                  controller.isSavingKotOrder.value
                      ? 'Sending...'
                      : 'Kitchen Bill',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
            const SizedBox(width: 10),
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
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _row('Subtotal', money(controller.subtotal)),
          const SizedBox(height: 9),
          _row('GST', money(controller.tax)),
          if (controller.discountType.value != 'none') ...[
            const SizedBox(height: 9),
            _row(
              'Discount',
              '- ${money(controller.discountAmount)}',
              color: AppColors.success,
            ),
          ],
          if (controller.chargeAmount.value > 0) ...[
            const SizedBox(height: 9),
            _row(
              'Charge',
              '+ ${money(controller.chargeAmount.value)}',
              color: AppColors.warning,
            ),
          ],
          const Divider(height: 24),
          _row(
            'Total',
            money(controller.total),
            style: TextHelper.totalAmountValue,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {TextStyle? style, Color? color}) {
    return Row(
      children: [
        Text(label, style: style ?? TextHelper.body),
        const Spacer(),
        Text(
          value,
          style: (style ?? TextHelper.bodySemiBold).copyWith(color: color),
        ),
      ],
    );
  }
}
