import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/texthelper.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/common_widgets.dart';

/// Left-side Category List Panel for Category Billing mode
class CategoryListPanel extends StatelessWidget {
  const CategoryListPanel({required this.controller, super.key});

  final HomeController controller;

  static IconData iconForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('beverage') ||
        lower.contains('drink') ||
        lower.contains('juice') ||
        lower.contains('water') ||
        lower.contains('tea') ||
        lower.contains('coffee') ||
        lower.contains('cola') ||
        lower.contains('soda')) {
      return Icons.local_cafe_rounded;
    }
    if (lower.contains('bakery') ||
        lower.contains('biscuit') ||
        lower.contains('cake') ||
        lower.contains('bread') ||
        lower.contains('pastry') ||
        lower.contains('cookie') ||
        lower.contains('bun')) {
      return Icons.bakery_dining_rounded;
    }
    if (lower.contains('snack') ||
        lower.contains('chip') ||
        lower.contains('mixture') ||
        lower.contains('namkeen') ||
        lower.contains('murukku') ||
        lower.contains('sev')) {
      return Icons.cookie_outlined;
    }
    if (lower.contains('sweet') ||
        lower.contains('chocolate') ||
        lower.contains('candy') ||
        lower.contains('icecream') ||
        lower.contains('dessert') ||
        lower.contains('halwa') ||
        lower.contains('laddu')) {
      return Icons.icecream_rounded;
    }
    if (lower.contains('grocer') ||
        lower.contains('detergent') ||
        lower.contains('oil') ||
        lower.contains('flour') ||
        lower.contains('rice') ||
        lower.contains('sugar') ||
        lower.contains('dal')) {
      return Icons.local_grocery_store_rounded;
    }
    if (lower.contains('personal') ||
        lower.contains('care') ||
        lower.contains('paste') ||
        lower.contains('soap') ||
        lower.contains('brush')) {
      return Icons.clean_hands_rounded;
    }
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Categories',
            trailing: IconButton(
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Refresh Categories',
              onPressed: () => controller.getCategories(),
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.yellowDark,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: (value) =>
                  controller.categorySearchQuery.value = value,
              decoration: const InputDecoration(
                hintText: 'Search category ID or name',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingCategories.value &&
                  controller.categories.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final error = controller.categoryError.value;
              final categories = controller.filteredCategories;

              if (error != null && categories.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          error,
                          textAlign: TextAlign.center,
                          style: TextHelper.poppins,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: controller.getCategories,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (categories.isEmpty) {
                return const Center(child: Text('No categories found'));
              }

              final selectedCat = controller.selectedCategory.value;

              return ListView.separated(
                padding: const EdgeInsets.all(10),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];

                  final isSelected =
                      selectedCat != null &&
                      selectedCat.toLowerCase() == cat.toLowerCase();

                  return _CategoryTileItem(
                    icon: iconForCategory(cat),
                    title: "$cat",
                    isSelected: isSelected,
                    onTap: () => controller.selectCategory(cat),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CategoryTileItem extends StatelessWidget {
  const _CategoryTileItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.yellowLight : AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.yellow : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.yellowDark
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.yellowDark
                        : AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Center(
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : AppColors.yellowDark,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected
                            ? AppColors.yellowDark
                            : AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.yellowDark,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Middle-side Products Panel for Category Billing mode
class CategoryProductsPanel extends StatelessWidget {
  const CategoryProductsPanel({
    required this.controller,
    this.searchFocusNode,
    super.key,
  });

  final HomeController controller;
  final FocusNode? searchFocusNode;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() {
            final selectedCat = controller.selectedCategory.value;
            final title = (selectedCat == null || selectedCat.isEmpty)
                ? 'Products'
                : selectedCat;
            final count = controller.categoryFilteredProducts.length;

            return SectionHeader(
              title: title,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.yellowLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count items',
                  style: const TextStyle(
                    color: AppColors.yellowDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: TextField(
              controller: controller.searchController,
              focusNode: searchFocusNode,
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
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (controller.selectedCategory.value == null) {
                return const Center(
                  child: Text('Select a category to view products'),
                );
              }
              final isLoading = controller.isLoadingDisplayedProducts;
              if (isLoading && controller.categoryFilteredProducts.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final error = controller.displayedProductsError;
              if (error != null &&
                  controller.categoryFilteredProducts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          error,
                          textAlign: TextAlign.center,
                          style: TextHelper.poppins,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            controller.retryDisplayedProducts();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final products = controller.categoryFilteredProducts;
              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text('No products found', style: TextHelper.poppins),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 220,
                ),
                itemCount: products.length,
                itemBuilder: (_, index) {
                  final product = products[index];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: ProductThumbnail(
                            path: product.image,
                            size: 70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${product.name} ${product.unit}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextHelper.bodySemiBold,
                        ),
                        if (product.productId.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Code: ${product.productId.trim()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextHelper.poppins,
                          ),
                        ],
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                money(product.price),
                                style: TextHelper.body,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Obx(() {
                              final cartItems = controller.cart.where(
                                (item) =>
                                    item.product.id == product.id &&
                                    item.product.unit == product.unit &&
                                    item.product.variantId == product.variantId,
                              );
                              final cartItem = cartItems.isNotEmpty
                                  ? cartItems.first
                                  : null;
                              final isAdded = cartItem != null;

                              return isAdded
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.yellowLight,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.yellow,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            borderRadius:
                                                const BorderRadius.horizontal(
                                                  left: Radius.circular(8),
                                                ),
                                            onTap:
                                                controller.isTakeAwayCartLocked
                                                ? null
                                                : () => controller.decrement(
                                                    cartItem,
                                                  ),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 6,
                                              ),
                                              child: Icon(
                                                Icons.remove_rounded,
                                                color: AppColors.yellowDark,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 2,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                            ),
                                            child: Text(
                                              '${cartItem.quantity}',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: AppColors.yellowDark,
                                                fontFamily: 'Poppins',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            borderRadius:
                                                const BorderRadius.horizontal(
                                                  right: Radius.circular(8),
                                                ),
                                            onTap:
                                                controller.isTakeAwayCartLocked
                                                ? null
                                                : () => controller.addProduct(
                                                    product,
                                                  ),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 6,
                                              ),
                                              child: Icon(
                                                Icons.add_rounded,
                                                color: AppColors.yellowDark,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : SoftIconButton(
                                      key: ValueKey(
                                        'cat-product-add-${product.id}',
                                      ),
                                      icon: Icons.add,
                                      onTap: controller.isTakeAwayCartLocked
                                          ? null
                                          : () =>
                                                controller.addProduct(product),
                                    );
                            }),
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
}
