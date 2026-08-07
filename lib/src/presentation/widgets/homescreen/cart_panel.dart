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
              trailing: TextButton.icon(
                onPressed: controller.cart.isEmpty
                    ? null
                    : () => _startNewBill(context),
                icon: const Icon(Icons.note_add_outlined, size: 18),
                label: const Text('New Bill'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.yellowDark,
                ),
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
                                maxLines: 3,
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
                              onTap: () => _deleteItem(context, item),
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
        ],
      ),
    );
  }

  void _startNewBill(BuildContext context) {
    controller.startNewBill();
    AppToast.show(context, 'A new bill has been started.');
  }

  void _deleteItem(BuildContext context, CartItem item) {
    controller.remove(item);
    AppToast.show(context, '${item.product.name} was removed from the bill.');
  }
}
