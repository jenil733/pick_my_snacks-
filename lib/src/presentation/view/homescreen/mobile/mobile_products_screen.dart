import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/texthelper.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/common_widgets.dart';

class MobileProductsScreen extends StatelessWidget {
  const MobileProductsScreen({
    required this.controller,
    required this.onOpenBill,
    super.key,
  });

  final HomeController controller;
  final VoidCallback onOpenBill;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: TextField(
            controller: controller.searchController,
            onChanged: (value) => controller.searchQuery.value = value,
            style: TextHelper.body,
            decoration: InputDecoration(
              hintText: 'Search products',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: Obx(
                () => controller.searchQuery.value.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          controller.searchController.clear();
                          controller.searchQuery.value = '';
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingProducts.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final error = controller.productError.value;
            if (error != null) {
              return _MessageState(
                icon: Icons.cloud_off_outlined,
                message: error,
                actionLabel: 'Retry',
                onAction: controller.getProducts,
              );
            }
            final products = controller.filteredProducts;
            if (products.isEmpty) {
              return const _MessageState(
                icon: Icons.search_off_rounded,
                message: 'No products found',
              );
            }
            final cartItems = List<CartItem>.generate(
              controller.cart.length,
              (index) => controller.cart[index],
              growable: false,
            );
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final product = products[index];
                final quantity = cartItems
                    .where((item) => item.product.id == product.id)
                    .fold(0, (sum, item) => sum + item.quantity);
                return Material(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => controller.addProduct(product),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ProductThumbnail(path: product.image, size: 56),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextHelper.bodySemiBold,
                                ),
                                const SizedBox(height: 3),
                                Text(product.unit, style: TextHelper.poppins),
                                if (product.productId.trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Code: ${product.productId.trim()}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextHelper.poppins,
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  money(product.price),
                                  style: TextHelper.bodySemiBold,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          quantity == 0
                              ? SizedBox.square(
                                  dimension: 42,
                                  child: IconButton.filled(
                                    tooltip: 'Add ${product.name}',
                                    onPressed: () =>
                                        controller.addProduct(product),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: const CircleBorder(),
                                    ),
                                    icon: const Icon(Icons.add_rounded),
                                  ),
                                )
                              : _QuantityControl(
                                  key: ValueKey(
                                    'product-quantity-${product.id}',
                                  ),
                                  quantity: quantity,
                                  onRemove: () {
                                    final item = controller.cart.firstWhere(
                                      (item) => item.product.id == product.id,
                                    );
                                    controller.decrement(item);
                                  },
                                  onAdd: () => controller.addProduct(product),
                                ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
        Obx(
          () => controller.cart.isEmpty
              ? const SizedBox.shrink()
              : Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: FilledButton(
                    onPressed: onOpenBill,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${controller.itemCount} items',
                          style: TextHelper.whiteButton,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'View bill  ${money(controller.total)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: TextHelper.whiteButton,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    super.key,
    required this.quantity,
    required this.onRemove,
    required this.onAdd,
  });

  final int quantity;
  final VoidCallback onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Remove one',
            onPressed: onRemove,
            icon: const Icon(Icons.remove_rounded, size: 18),
          ),
          SizedBox(
            width: 20,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextHelper.bodySemiBold,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Add one',
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.divider),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: TextHelper.body),
            if (actionLabel != null) ...[
              const SizedBox(height: 10),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
