import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/app_toast.dart';
import 'package:pick_my_snacks/src/core/utils/helper/texthelper.dart';
import 'package:pick_my_snacks/src/data/model/get_hold.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/common_widgets.dart';

Future<void> showHeldBillsPanel(
  BuildContext context,
  HomeController controller,
) {
  controller.getHoldOrders();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close held bills',
    barrierColor: Colors.black.withValues(alpha: .32),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) => Align(
      alignment: Alignment.centerRight,
      child: HeldBillsPanel(controller: controller),
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

class HeldBillsPanel extends StatelessWidget {
  const HeldBillsPanel({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: AppColors.surface,
        elevation: 18,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width.clamp(0, 390).toDouble(),
          height: double.infinity,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                color: AppColors.navy,
                child: Row(
                  children: [
                    const Icon(
                      Icons.pause_circle_outline_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Held Bills', style: TextHelper.appBarTitle),
                    ),
                    Obx(
                      () => IconButton(
                        tooltip: 'Refresh held bills',
                        onPressed: controller.isLoadingHeldOrders.value
                            ? null
                            : controller.getHoldOrders,
                        icon: controller.isLoadingHeldOrders.value
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                              ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.isLoadingHeldOrders.value &&
                      controller.heldOrderSummaries.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final error = controller.heldOrdersError.value;
                  if (error != null &&
                      controller.heldOrderSummaries.isEmpty &&
                      controller.heldBills.isEmpty) {
                    return _HeldOrdersMessage(
                      message: error,
                      onRetry: controller.getHoldOrders,
                    );
                  }

                  if (controller.heldOrderSummaries.isNotEmpty) {
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.heldOrderSummaries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final order = controller.heldOrderSummaries[index];
                        return _BackendHeldOrderCard(
                          order: order,
                          isLoading:
                              controller.resumingOrderId.value == order.id,
                          isDeleting:
                              controller.deletingOrderId.value == order.id,
                          onContinue: () =>
                              _continueBackendOrder(context, order),
                          onDelete: () => _deleteBackendOrder(context, order),
                        );
                      },
                    );
                  }

                  if (controller.heldBills.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            size: 52,
                            color: AppColors.divider,
                          ),
                          const SizedBox(height: 12),
                          Text('No held bills', style: TextHelper.sectionTitle),
                          const SizedBox(height: 4),
                          Text(
                            'Bills you hold will appear here',
                            style: TextHelper.poppins,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.heldBills.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final bill = controller.heldBills[index];
                      return _HeldBillCard(
                        bill: bill,
                        onTap: () => _continueBill(context, bill),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _continueBill(BuildContext context, HeldBill bill) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Continue Bill #${bill.id}?',
      message: controller.cart.isNotEmpty
          ? 'Your current cart will be replaced with this held bill. Do you want to continue?'
          : 'This bill will return to the cart. Do you want to continue billing?',
      confirmLabel: 'Continue',
      icon: Icons.play_circle_outline_rounded,
      confirmColor: AppColors.success,
    );
    if (!confirmed) return;

    controller.restoreHeldBill(bill);
    if (!context.mounted) return;
    AppToast.show(
      context,
      'Bill #${bill.id} restored. Products are available in the cart.',
    );
    Navigator.of(context).pop();
  }

  Future<void> _continueBackendOrder(
    BuildContext context,
    HeldOrderSummary order,
  ) async {
    final label = order.orderId ?? '#${order.id ?? '-'}';
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Continue $label?',
      message: controller.cart.isNotEmpty
          ? 'Your current cart will be replaced with this held order.'
          : 'The held products will be restored to your cart.',
      confirmLabel: 'Continue',
      icon: Icons.play_circle_outline_rounded,
      confirmColor: AppColors.success,
    );
    if (!confirmed) return;

    final resumed = await controller.resumeHeldOrder(order);
    if (!context.mounted) return;
    if (!resumed) {
      AppToast.error(
        context,
        controller.resumeOrderError.value ?? 'Please try again.',
      );
      return;
    }

    AppToast.show(context, '$label resumed. Products restored to the cart.');
    Navigator.of(context).pop();
  }

  Future<void> _deleteBackendOrder(
    BuildContext context,
    HeldOrderSummary order,
  ) async {
    final label = order.orderId ?? '#${order.id ?? '-'}';
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete $label?',
      message: 'This held order will be permanently deleted.',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
      confirmColor: AppColors.error,
    );
    if (!confirmed) return;

    final deleted = await controller.deleteHeldOrder(order);
    if (!context.mounted) return;
    if (!deleted) {
      AppToast.error(
        context,
        controller.deleteHeldBillError.value ?? 'Please try again.',
      );
      return;
    }

    AppToast.show(context, '$label was deleted successfully.');
  }
}

class _BackendHeldOrderCard extends StatelessWidget {
  const _BackendHeldOrderCard({
    required this.order,
    required this.onContinue,
    required this.onDelete,
    required this.isLoading,
    required this.isDeleting,
  });

  final HeldOrderSummary order;
  final VoidCallback onContinue;
  final VoidCallback onDelete;
  final bool isLoading;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final orderLabel = order.orderId?.trim().isNotEmpty == true
        ? order.orderId!.trim()
        : '#${order.id ?? '-'}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pause_circle_outline_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(orderLabel, style: TextHelper.bodySemiBold),
                    const SizedBox(height: 3),
                    Text(
                      '${order.itemsCount ?? 0} items'
                      '${order.dateTime == null ? '' : ' • ${order.dateTime}'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextHelper.caption,
                    ),
                    if (order.paymentMode?.isNotEmpty == true) ...[
                      const SizedBox(height: 3),
                      Text(
                        order.paymentMode!.toUpperCase(),
                        style: TextHelper.primaryBody,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(money(order.total ?? 0), style: TextHelper.bodySemiBold),
                  const SizedBox(height: 3),
                  Text(order.status ?? 'hold', style: TextHelper.caption),
                ],
              ),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading || isDeleting ? null : onContinue,
                  icon: isLoading
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 19),
                  label: Text(isLoading ? 'Continuing...' : 'Continue'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(42),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isLoading || isDeleting ? null : onDelete,
                  icon: isDeleting
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_outline_rounded, size: 19),
                  label: Text(isDeleting ? 'Deleting...' : 'Delete'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    minimumSize: const Size.fromHeight(42),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeldOrdersMessage extends StatelessWidget {
  const _HeldOrdersMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextHelper.poppins,
            ),
            const SizedBox(height: 14),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _HeldBillCard extends StatelessWidget {
  const _HeldBillCard({required this.bill, required this.onTap});

  final HeldBill bill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bill #${bill.id}', style: TextHelper.bodySemiBold),
                    const SizedBox(height: 3),
                    Text(
                      '${bill.itemCount} items • ${_formatTime(bill.createdAt)}',
                      style: TextHelper.caption,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(money(bill.total), style: TextHelper.bodySemiBold),
                  const SizedBox(height: 4),
                  Text('Continue', style: TextHelper.primaryBody),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
