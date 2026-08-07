import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/texthelper.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/common_widgets.dart';

class StockNotificationsScreen extends StatelessWidget {
  const StockNotificationsScreen({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Stock Notifications',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          actions: [
            Obx(
              () => IconButton(
                tooltip: 'Refresh stock',
                onPressed: controller.isLoadingStockNotifications
                    ? null
                    : controller.refreshStockNotifications,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Obx(() {
                final lowStock = controller.lowStockProducts;
                final outOfStock = controller.outOfStockProducts;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Material(
                      color: AppColors.surface,
                      child: TabBar(
                        labelColor: AppColors.yellowDark,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: AppColors.border,
                        tabs: [
                          _StockTabLabel(
                            label: 'Low Stock',
                            count: lowStock.length,
                            color: AppColors.warning,
                          ),
                          _StockTabLabel(
                            label: 'Out of Stock',
                            count: outOfStock.length,
                            color: AppColors.error,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child:
                          controller.isLoadingStockNotifications &&
                              lowStock.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : TabBarView(
                              children: [
                                _StockList(
                                  products: lowStock,
                                  emptyMessage: 'No low-stock products',
                                  statusColor: AppColors.warning,
                                  statusIcon: Icons.inventory_2_outlined,
                                  onRefresh:
                                      controller.refreshStockNotifications,
                                ),
                                _StockList(
                                  products: outOfStock,
                                  emptyMessage: 'No out-of-stock products',
                                  statusColor: AppColors.error,
                                  statusIcon:
                                      Icons.remove_shopping_cart_outlined,
                                  onRefresh:
                                      controller.refreshStockNotifications,
                                ),
                              ],
                            ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _StockTabLabel extends StatelessWidget {
  const _StockTabLabel({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 58,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(minWidth: 24),
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockList extends StatelessWidget {
  const _StockList({
    required this.products,
    required this.emptyMessage,
    required this.statusColor,
    required this.statusIcon,
    required this.onRefresh,
  });

  final List<Product> products;
  final String emptyMessage;
  final Color statusColor;
  final IconData statusIcon;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * .22),
            Icon(statusIcon, size: 54, color: AppColors.textSecondary),
            const SizedBox(height: 14),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextHelper.bodySemiBold.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _StockNotificationCard(
          product: products[index],
          statusColor: statusColor,
        ),
      ),
    );
  }
}

class _StockNotificationCard extends StatelessWidget {
  const _StockNotificationCard({
    required this.product,
    required this.statusColor,
  });

  final Product product;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final stock = product.stock ?? 0;
    final stockText = stock % 1 == 0
        ? stock.toInt().toString()
        : stock.toString();

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ProductThumbnail(path: product.image, size: 58, padding: 6),
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
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (product.productId.trim().isNotEmpty)
                        'Code: ${product.productId.trim()}',
                      if (product.unit.trim().isNotEmpty) product.unit.trim(),
                    ].join('  •  '),
                    style: TextHelper.poppins.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '$stockText left',
                style: TextStyle(
                  color: statusColor,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
