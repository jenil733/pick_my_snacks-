import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/texthelper.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/bill_summary_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/common_widgets.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/payment_method_dropdown.dart';

class MobileBillingScreen extends StatelessWidget {
  const MobileBillingScreen({
    required this.controller,
    required this.onNewBill,
    super.key,
  });

  final HomeController controller;
  final VoidCallback onNewBill;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Bill Summary', style: TextHelper.title),
                const SizedBox(height: 12),
                _SummaryCard(controller: controller),
                const SizedBox(height: 12),
                PaymentMethodDropdown(controller: controller),
                const SizedBox(height: 20),
                Text('Items in bill', style: TextHelper.sectionTitle),
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextHelper.body,
                                    ),
                                  ),
                                  Text(
                                    '${item.displayUnit}  x${item.quantity}',
                                    style: TextHelper.poppins,
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 72,
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
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed:
                        controller.isSavingOrder.value ||
                            controller.isHoldingOrder.value
                        ? null
                        : () => startNewBill(controller, onStarted: onNewBill),
                    icon: const Icon(Icons.note_add_outlined, size: 19),
                    label: const Text('New Bill'),
                    style: FilledButton.styleFrom(
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
                              : 'Hold Bill',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
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
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.print_rounded, size: 19),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                controller.isSavingOrder.value
                                    ? 'Saving Order...'
                                    : 'Print Receipt',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(money(controller.total)),
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

  Widget _row(String label, String value, {TextStyle? style}) {
    return Row(
      children: [
        Text(label, style: style ?? TextHelper.body),
        const Spacer(),
        Text(value, style: style ?? TextHelper.bodySemiBold),
      ],
    );
  }
}
