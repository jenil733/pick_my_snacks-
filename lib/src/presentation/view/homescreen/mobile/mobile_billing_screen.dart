import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/app_toast.dart';
import 'package:pick_my_snacks/src/core/utils/helper/texthelper.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/bill_adjustment_dialogs.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/bill_summary_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/common_widgets.dart';
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
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.product.name,
                                      maxLines: 3,
                                      style: TextHelper.body,
                                    ),
                                  ),
                                  Text(
                                    item.displayUnit,
                                    style: TextHelper.poppins,
                                  ),
                                  const SizedBox(width: 8),
                                  BillQuantityControl(
                                    controller: controller,
                                    item: item,
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 62,
                                    child: Text(
                                      money(item.total),
                                      textAlign: TextAlign.right,
                                      style: TextHelper.bodySemiBold,
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
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: const ValueKey('mobile-new-bill'),
                        onPressed:
                            controller.isSavingOrder.value ||
                                controller.isHoldingOrder.value
                            ? null
                            : () {
                                controller.startNewBill();
                                AppToast.show(
                                  context,
                                  'A new bill has been started.',
                                );
                              },
                        icon: const Icon(Icons.note_add_outlined, size: 19),
                        label: const Text('New Bill'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.yellow,
                          foregroundColor: Colors.white,
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
                            controller.cart.isEmpty ||
                                controller.isSavingOrder.value
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            controller.cart.isEmpty ||
                                controller.isHoldingOrder.value
                            ? null
                            : () => holdBill(context, controller),
                        icon: const Icon(
                          Icons.pause_circle_outline_rounded,
                          size: 18,
                        ),
                        label: Text(
                          controller.isHoldingOrder.value
                              ? 'Holding...'
                              : 'Hold',
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
                      flex: 2,
                      child: FilledButton(
                        onPressed:
                            controller.cart.isEmpty ||
                                controller.isSavingOrder.value
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
                ),
              ],
            ),
          ),
        ],
      ),
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
