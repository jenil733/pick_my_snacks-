import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/app_toast.dart';
import 'package:pick_my_snacks/src/core/utils/helper/texthelper.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/staff/staff_controller.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/common_widgets.dart';

class CartPanel extends StatelessWidget {
  const CartPanel({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: Column(
        children: [
          Obx(
            () => SectionHeader(
              title: 'Selected Items (${controller.itemCount})',
              trailing: TextButton.icon(
                onPressed: controller.cart.isEmpty
                    ? null
                    : () => _confirmClearCart(context),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text('Clear All', style: TextHelper.deleteButton),
                style: TextButton.styleFrom(foregroundColor: AppColors.delete),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (controller.cart.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shopping_cart_outlined,
                        size: 44,
                        color: AppColors.divider,
                      ),
                      const SizedBox(height: 10),
                      Text('Your cart is empty', style: TextHelper.body),
                      Text(
                        'Add a product to start billing',
                        style: TextHelper.caption,
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: controller.cart.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final item = controller.cart[index];
                  return Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        ProductThumbnail(path: item.product.image, size: 52),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.product.name} ${item.displayUnit}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextHelper.bodySemiBold,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                money(item.product.price),
                                style: TextHelper.body,
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Total: ${money(item.total)}',
                                  style: TextHelper.body,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SoftIconButton(
                              icon: Icons.remove,
                              onTap: () => controller.decrement(item),
                              color: AppColors.textSecondary,
                              size: 28,
                            ),
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${item.quantity}',
                                textAlign: TextAlign.center,
                                style: TextHelper.body,
                              ),
                            ),
                            SoftIconButton(
                              icon: Icons.add,
                              onTap: () => controller.increment(item),
                              size: 28,
                            ),
                            const SizedBox(width: 5),
                            SoftIconButton(
                              icon: Icons.delete_outline,
                              onTap: () => _confirmDeleteItem(context, item),
                              color: AppColors.delete,
                              size: 28,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
          Obx(
            () => Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          controller.cart.isEmpty ||
                              controller.isHoldingOrder.value
                          ? null
                          : () => _confirmHoldBill(context),
                      icon: const Icon(Icons.pause_circle_outline, size: 18),
                      label: Text(
                        controller.isHoldingOrder.value
                            ? 'Holding Order...'
                            : 'Hold Bill',
                        style: TextHelper.whiteButton,
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearCart(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Clear all items?',
      message: 'This will remove every product from the current bill.',
      confirmLabel: 'Clear All',
      icon: Icons.delete_sweep_outlined,
      confirmColor: AppColors.delete,
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    controller.clearCart();
    AppToast.show(context, 'All items were removed from the current bill.');
  }

  Future<void> _confirmDeleteItem(BuildContext context, CartItem item) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete this item?',
      message: '${item.product.name} will be removed from the bill.',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
      confirmColor: AppColors.delete,
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    controller.remove(item);
    AppToast.show(context, '${item.product.name} was removed from the bill.');
  }

  Future<void> _confirmHoldBill(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Hold this bill?',
      message:
          'The current bill will be saved in Held Bills so you can continue it later.',
      confirmLabel: 'Hold Bill',
      icon: Icons.pause_circle_outline_rounded,
    );
    if (!confirmed) return;
    final staffController = Get.isRegistered<StaffController>()
        ? Get.find<StaffController>()
        : null;
    final bill = await controller.holdOrder(
      staffId: staffController?.selectedStaff.value?.id,
    );
    if (!context.mounted) return;
    if (bill == null) {
      AppToast.error(
        context,
        controller.holdOrderError.value ?? 'Please try again.',
      );
      return;
    }
    AppToast.show(
      context,
      'Bill #${bill.id} held. You can reopen it from Held Bills.',
    );
  }
}
