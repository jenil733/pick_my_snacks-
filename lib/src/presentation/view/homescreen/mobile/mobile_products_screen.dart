import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/texthelper.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/category_billing_panel.dart';
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
    return Obx(() {
      if (controller.flow.value == PosFlow.categoryBilling &&
          controller.selectedCategory.value == null) {
        return MobileCategoryCards(controller: controller);
      }
      return Column(
        children: [
          if (controller.flow.value == PosFlow.categoryBilling)
            ListTile(
              leading: IconButton(
                tooltip: 'Back to categories',
                icon: const Icon(Icons.arrow_back),
                onPressed: controller.clearSelectedCategory,
              ),
              title: Text(
                controller.selectedCategory.value ?? '',
                style: TextHelper.bodySemiBold,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: controller.searchController,
              onChanged: (value) => controller.searchQuery.value = value,
              style: TextHelper.body,
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextHelper.poppins,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: Obx(
                  () => controller.searchQuery.value.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            controller.searchController.clear();
                            controller.searchQuery.value = '';
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                ),
                filled: true,
                fillColor: AppColors.searchbox,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
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
              final displayedProducts =
                  controller.flow.value == PosFlow.categoryBilling
                  ? controller.categoryFilteredProducts
                  : controller.filteredProducts;
              final isLoading = controller.isLoadingDisplayedProducts;
              if (isLoading && displayedProducts.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final error = controller.displayedProductsError;
              if (error != null && displayedProducts.isEmpty) {
                return _MessageState(
                  icon: Icons.cloud_off_outlined,
                  message: error,
                  actionLabel: 'Retry',
                  onAction: () {
                    controller.retryDisplayedProducts();
                  },
                );
              }
              final products = controller.flow.value == PosFlow.categoryBilling
                  ? controller.categoryFilteredProducts
                  : controller.filteredProducts;
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
                  final cartItem = cartItems.firstWhereOrNull(
                    (item) => item.product.id == product.id,
                  );
                  return Material(
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: controller.isTakeAwayCartLocked
                          ? null
                          : () => controller.addProduct(product),
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
                            cartItem == null
                                ? SizedBox.square(
                                    dimension: 42,
                                    child: IconButton.filled(
                                      tooltip: 'Add ${product.name}',
                                      onPressed: controller.isTakeAwayCartLocked
                                          ? null
                                          : () =>
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
                                    controller: controller,
                                    item: cartItem,
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
    });
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    super.key,
    required this.controller,
    required this.item,
  });

  final HomeController controller;
  final CartItem item;

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
            onPressed: controller.isTakeAwayCartLocked
                ? null
                : () => controller.decrement(item),
            icon: const Icon(Icons.remove_rounded, size: 18),
          ),
          EditableItemAmount(controller: controller, item: item, width: 34),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Add one',
            onPressed: controller.isTakeAwayCartLocked
                ? null
                : () => controller.increment(item),
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

class MobileCategoryCards extends StatelessWidget {
  const MobileCategoryCards({required this.controller, super.key});
  final HomeController controller;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          initialValue: controller.categorySearchQuery.value,
          onChanged: (value) => controller.categorySearchQuery.value = value,
          decoration: const InputDecoration(
            hintText: 'Search category by ID or name',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
      ),
      Expanded(
        child: Obx(() {
          if (controller.isLoadingCategories.value &&
              controller.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final error = controller.categoryError.value;
          if (error != null) {
            return _MessageState(
              icon: Icons.cloud_off_outlined,
              message: error,
              actionLabel: 'Retry',
              onAction: controller.getCategories,
            );
          }
          final categories = controller.filteredCategories;
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found'));
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 150,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final name = categories[index];
              final id = controller.billingCategories
                  .firstWhereOrNull((item) => item.name == name)
                  ?.id;
              return Card(
                margin: EdgeInsets.zero,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => controller.selectCategory(name),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CategoryListPanel.iconForCategory(name),
                          size: 30,
                          color: AppColors.yellowDark,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          name,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextHelper.bodySemiBold,
                        ),
                        if (id != null)
                          Text('ID: $id', style: TextHelper.poppins),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    ],
  );
}
