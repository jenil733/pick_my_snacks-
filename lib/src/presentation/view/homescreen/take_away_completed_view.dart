import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/data/model/take_away_processing.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';

class TakeAwayCompletedView extends StatefulWidget {
  const TakeAwayCompletedView({
    super.key,
    required this.controller,
    required this.completedOrderId,
    required this.holdOrderId,
  });

  final HomeController controller;
  final int completedOrderId;
  final int holdOrderId;

  @override
  State<TakeAwayCompletedView> createState() => _TakeAwayCompletedViewState();
}

class _TakeAwayCompletedViewState extends State<TakeAwayCompletedView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() => widget.controller.getCompletedTakeAwayView(
    widget.completedOrderId,
    widget.holdOrderId,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Completed Take Away'),
        actions: [
          IconButton(
            tooltip: 'Refresh order',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Obx(() {
        if (widget.controller.isLoadingCompletedTakeAwayView.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final error = widget.controller.completedTakeAwayViewError.value;
        final order = widget.controller.completedTakeAwayOrderView.value;
        if (error != null || order == null) {
          return _CompletedViewError(
            message: error ?? 'Completed order was not found.',
            onRetry: _load,
          );
        }
        return _CompletedOrderBody(order: order);
      }),
    );
  }
}

class _CompletedOrderBody extends StatelessWidget {
  const _CompletedOrderBody({required this.order});

  final TakeAwayProcessingOrder order;

  @override
  Widget build(BuildContext context) {
    final total =
        order.total ??
        order.products.fold<double>(
          0,
          (sum, product) => sum + (product.rowTotal ?? 0),
        );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          color: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderId ?? '#${order.id ?? '-'}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Customer',
                  value: order.customerName ?? '-',
                ),
                _DetailRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: order.customerPhone ?? '-',
                ),
                _DetailRow(
                  icon: Icons.badge_outlined,
                  label: 'Staff',
                  value: order.staffName ?? '-',
                ),
                _DetailRow(
                  icon: Icons.task_alt_rounded,
                  label: 'Status',
                  value: order.status ?? 'Completed',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Products', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (order.products.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No products found for this order.'),
            ),
          )
        else
          ...order.products.map(
            (product) => Card(
              color: AppColors.surface,
              child: ListTile(
                title: Text(
                  product.productName ?? 'Product ${product.productId ?? '-'}',
                ),
                subtitle: Text(
                  product?.unit == 'kg'
                      ? '${product.quantity ?? '-'} ${product.unit ?? ''}'
                            .trim()
                      : '${num.parse(product.quantity ?? '0.00').toInt()} ${product.unit ?? ''}'
                            .trim(),
                ),
                trailing: Text(
                  '₹${(product.rowTotal ?? 0).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Card(
          color: AppColors.navy,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(color: AppColors.text, fontSize: 18),
                ),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          SizedBox(width: 82, child: Text(label)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedViewError extends StatelessWidget {
  const _CompletedViewError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
