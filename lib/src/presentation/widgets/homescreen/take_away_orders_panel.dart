import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/texthelper.dart';
import 'package:pick_my_snacks/src/data/model/take_away_processing.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/view/homescreen/take_away_completed_view.dart';

enum TakeAwayOrdersTab { pending, completed }

Future<void> showTakeAwayOrdersPanel(
  BuildContext context,
  HomeController controller, {
  required TakeAwayOrdersTab initialTab,
}) {
  if (initialTab == TakeAwayOrdersTab.pending) {
    controller.getTakeAwayProcessing();
  } else {
    controller.getTakeAwayCompleted();
  }
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close take-away orders',
    barrierColor: Colors.black.withValues(alpha: .32),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, _, _) => Align(
      alignment: Alignment.centerRight,
      child: _TakeAwayOrdersPanel(
        controller: controller,
        initialTab: initialTab,
      ),
    ),
    transitionBuilder: (_, animation, _, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

class _TakeAwayOrdersPanel extends StatefulWidget {
  const _TakeAwayOrdersPanel({
    required this.controller,
    required this.initialTab,
  });

  final HomeController controller;
  final TakeAwayOrdersTab initialTab;

  @override
  State<_TakeAwayOrdersPanel> createState() => _TakeAwayOrdersPanelState();
}

class _TakeAwayOrdersPanelState extends State<_TakeAwayOrdersPanel> {
  late TakeAwayOrdersTab _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: AppColors.surface,
        elevation: 18,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width.clamp(0, 410).toDouble(),
          height: double.infinity,
          child: Column(
            children: [
              _header(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: SegmentedButton<TakeAwayOrdersTab>(
                  segments: const [
                    ButtonSegment(
                      value: TakeAwayOrdersTab.pending,
                      icon: Icon(Icons.pending_actions_rounded),
                      label: Text('Pending'),
                    ),
                    ButtonSegment(
                      value: TakeAwayOrdersTab.completed,
                      icon: Icon(Icons.task_alt_rounded),
                      label: Text('Completed'),
                    ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (selection) {
                    final selected = selection.first;
                    setState(() => _tab = selected);
                    if (selected == TakeAwayOrdersTab.pending) {
                      widget.controller.getTakeAwayProcessing();
                    } else {
                      widget.controller.getTakeAwayCompleted();
                    }
                  },
                ),
              ),
              Expanded(child: Obx(_content)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
      child: Row(
        children: [
          const Icon(Icons.takeout_dining_rounded, color: Colors.white),
          const SizedBox(width: 9),
          Expanded(
            child: Text('Take Away Orders', style: TextHelper.appBarTitle),
          ),
          IconButton(
            tooltip: 'Refresh orders',
            onPressed:
                (_tab == TakeAwayOrdersTab.pending
                    ? widget.controller.isLoadingTakeAwayProcessing.value
                    : widget.controller.isLoadingTakeAwayCompleted.value)
                ? null
                : () {
                    if (_tab == TakeAwayOrdersTab.pending) {
                      widget.controller.getTakeAwayProcessing();
                    } else {
                      widget.controller.getTakeAwayCompleted();
                    }
                  },
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    final controller = widget.controller;
    if (_tab == TakeAwayOrdersTab.pending) {
      if (controller.isLoadingTakeAwayProcessing.value &&
          controller.takeAwayProcessingOrders.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      final error = controller.takeAwayProcessingError.value;
      if (error != null && controller.takeAwayProcessingOrders.isEmpty) {
        return _EmptyOrders(message: error);
      }
      return _ordersList(
        controller.takeAwayProcessingOrders,
        emptyMessage: 'No pending take-away orders',
        allowClose: true,
      );
    }
    if (controller.isLoadingTakeAwayCompleted.value &&
        controller.completedTakeAwayOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final completedError = controller.takeAwayCompletedError.value;
    if (completedError != null && controller.completedTakeAwayOrders.isEmpty) {
      return _EmptyOrders(message: completedError);
    }
    return _ordersList(
      controller.completedTakeAwayOrders,
      emptyMessage: 'No completed take-away orders',
      allowView: true,
    );
  }

  Widget _ordersList(
    List<TakeAwayProcessingOrder> orders, {
    required String emptyMessage,
    bool allowClose = false,
    bool allowView = false,
  }) {
    if (orders.isEmpty) return _EmptyOrders(message: emptyMessage);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final order = orders[index];
        return _TakeAwayOrderCard(
          order: order,
          isOpening:
              allowClose &&
              widget.controller.openingPendingTakeAwayOrderId.value ==
                  (order.holdOrderId ?? order.id),
          onClose: allowClose && order.id != null
              ? () => _openOrder(order)
              : null,
          onView: allowView && order.id != null
              ? () => _viewCompletedOrder(order)
              : null,
        );
      },
    );
  }

  Future<void> _openOrder(TakeAwayProcessingOrder order) async {
    final opened = await widget.controller.openPendingTakeAwayOrderForBilling(
      order,
    );
    if (!mounted) return;
    if (opened) {
      Navigator.of(context, rootNavigator: true).pop();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.controller.takeAwayProcessingError.value ??
              'Unable to load the pending bill.',
        ),
      ),
    );
  }

  void _viewCompletedOrder(TakeAwayProcessingOrder order) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => TakeAwayCompletedView(
          controller: widget.controller,
          completedOrderId: order.id!,
          holdOrderId: order.holdOrderId ?? order.id!,
        ),
      ),
    );
  }
}

class _TakeAwayOrderCard extends StatelessWidget {
  const _TakeAwayOrderCard({
    required this.order,
    this.onClose,
    this.onView,
    this.isOpening = false,
  });

  final TakeAwayProcessingOrder order;
  final VoidCallback? onClose;
  final VoidCallback? onView;
  final bool isOpening;

  @override
  Widget build(BuildContext context) {
    final orderLabel = order.orderId?.trim().isNotEmpty == true
        ? order.orderId!
        : '#${order.id ?? '-'}';
    return Card(
      color: onView == null ? null : const Color(0xFFE8F5E9),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(orderLabel, style: TextHelper.sectionTitle),
                ),
                if (onView != null)
                  const Chip(
                    backgroundColor: Color(0xFFC8E6C9),
                    label: Text(
                      'Completed',
                      style: TextStyle(
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (order.customerName?.trim().isNotEmpty == true)
              Text('Customer: ${order.customerName}'),
            if (order.customerPhone?.trim().isNotEmpty == true)
              Text('Phone: ${order.customerPhone}'),
            if (order.staffName?.trim().isNotEmpty == true)
              Text('Staff: ${order.staffName}'),
            if (order.products.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...order.products.map(
                (product) => Text(
                  '${product.productName ?? 'Product ${product.productId ?? '-'}'} '
                  '× ${product.quantity ?? '-'} ${product.unit ?? ''}'
                  '${product.rowTotal == null ? '' : '  ₹${product.rowTotal!.toStringAsFixed(2)}'}',
                ),
              ),
            ],
            if (onClose != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isOpening ? null : onClose,
                  icon: isOpening
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.receipt_long_rounded),
                  label: Text(isOpening ? 'Opening...' : 'Close Bill'),
                ),
              ),
            ],
            if (onView != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_rounded),
                  label: const Text('View Order'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 52,
              color: AppColors.divider,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
