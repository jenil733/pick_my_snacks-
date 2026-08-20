import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/app_toast.dart';
import 'package:pick_my_snacks/src/core/utils/helper/texthelper.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
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
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (controller.flow.value == PosFlow.kot ||
                                controller.flow.value == PosFlow.takeAway) ...[
                              Tooltip(
                                message:
                                    controller.flow.value == PosFlow.takeAway
                                    ? 'Include ${item.product.name} in Kitchen Bill'
                                    : 'Send ${item.product.name} to kitchen',
                                child: Checkbox(
                                  value: controller.isKitchenItemSelected(item),
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
                            ProductThumbnail(
                              path: item.product.image,
                              size: 52,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.product.name,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextHelper.bodySemiBold,
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
                                EditableItemAmount(
                                  controller: controller,
                                  item: item,
                                ),
                                SoftIconButton(
                                  icon: Icons.add,
                                  onTap: () => controller.increment(item),
                                  size: 28,
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 72,
                              child: Column(
                                children: [
                                  SoftIconButton(
                                    icon: Icons.delete_outline,
                                    onTap: () => _deleteItem(context, item),
                                    color: AppColors.delete,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 5),
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
                        if (controller.flow.value == PosFlow.kot ||
                            controller.flow.value == PosFlow.takeAway) ...[
                          const SizedBox(height: 9),
                          ExtraItemNoteField(
                            key: ValueKey('extra-${item.uniqueId}'),
                            controller: controller,
                            item: item,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
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
}
