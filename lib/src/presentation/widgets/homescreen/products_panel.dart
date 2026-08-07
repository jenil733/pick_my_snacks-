import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/texthelper.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/common_widgets.dart';

class ProductsPanel extends StatelessWidget {
  const ProductsPanel({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: Column(
        children: [
          const SectionHeader(
            title: 'Products',
            trailing: Row(mainAxisSize: MainAxisSize.min),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: TextField(
              controller: controller.searchController,
              onChanged: (value) => controller.searchQuery.value = value,
              style: TextHelper.body,
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextHelper.poppins,
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.searchbox,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
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
              if (controller.isLoadingProducts.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final error = controller.productError.value;
              if (error != null) {
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
                          onPressed: controller.getProducts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final products = controller.filteredProducts;
              if (products.isEmpty) {
                return Center(
                  child: Text('No products found', style: TextHelper.poppins),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final product = products[index];
                  return Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ProductThumbnail(
                            path: product.image,
                            size: 48,
                            padding: 0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${product.name} ${product.unit}',
                                maxLines: 1,
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
                              const SizedBox(height: 3),
                              Text(
                                money(product.price),
                                style: TextHelper.body,
                              ),
                            ],
                          ),
                        ),
                        Obx(() {
                          final hasCartItems = controller.cart.isNotEmpty;
                          final isAdded =
                              hasCartItems &&
                              controller.cart.any(
                                (item) => item.product.id == product.id,
                              );
                          return isAdded
                              ? Tooltip(
                                  message: 'Add another ${product.name}',
                                  child: InkWell(
                                    key: ValueKey(
                                      'product-add-another-${product.id}',
                                    ),
                                    onTap: () => controller.addProduct(product),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.yellowLight,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.yellow,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add_rounded,
                                            color: AppColors.yellowDark,
                                            size: 16,
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            '+1',
                                            style: TextStyle(
                                              color: AppColors.yellowDark,
                                              fontFamily: 'Poppins',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : SoftIconButton(
                                  key: ValueKey('product-add-${product.id}'),
                                  icon: Icons.add,
                                  onTap: () => controller.addProduct(product),
                                );
                        }),
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
