import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/data/model/get_table_status.dart';
import 'package:pick_my_snacks/src/data/model/processing.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/staff/staff_controller.dart';

class KotTablesView extends StatelessWidget {
  const KotTablesView({required this.controller, this.onOpenOrder, super.key});

  final HomeController controller;
  final VoidCallback? onOpenOrder;
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final orders = Map<int, KotTableOrder>.from(controller.tableOrders);
      final submittedTables = Set<int>.from(controller.submittedKitchenTables);
      final statuses = Map<int, TableStatusData>.from(controller.tableStatuses);
      final processingOrders = Map<int, ProcessingOrderData>.from(
        controller.processingOrders,
      );
      final tableNumbers = controller.availableTableNumbers;
      final isLoading = controller.isLoadingTables.value;
      final isLoadingStatuses = controller.isLoadingTableStatuses.value;
      final error = controller.tableError.value;
      final statusError = controller.tableStatusError.value;
      final processingData = controller.processingOrder.value;
      final isLoadingProcessing = controller.isLoadingProcessingOrder.value;
      final processingError = controller.processingOrderError.value;
      final selectedTableNumber = controller.selectedKotTableNumber.value;
      final selectedOrder = selectedTableNumber == null
          ? null
          : orders[selectedTableNumber];
      if (controller.kotStage.value == KotStage.details) {
        if (selectedOrder != null) {
          return _KotTableDetailsView(
            order: selectedOrder,
            onContinue: () {
              controller.continueKotTable(selectedOrder.tableNumber);
              onOpenOrder?.call();
            },
          );
        }
        return _ProcessingTableDetailsView(
          tableNumber: selectedTableNumber,
          data: processingData,
          isLoading: isLoadingProcessing,
          error: processingError,
          onRetry: selectedTableNumber == null
              ? null
              : () => controller.getProcessingOrder(selectedTableNumber),
          onContinue: () {
            controller.continueProcessingOrder();
            onOpenOrder?.call();
          },
        );
      }
      if (isLoading && tableNumbers.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (error != null && tableNumbers.isEmpty) {
        return _TableLoadState(
          icon: Icons.cloud_off_outlined,
          message: error,
          actionLabel: 'Retry',
          onAction: controller.getTables,
        );
      }
      if (tableNumbers.isEmpty) {
        return _TableLoadState(
          icon: Icons.table_restaurant_outlined,
          message: 'No tables are available.',
          actionLabel: 'Refresh',
          onAction: controller.getTables,
        );
      }
      return _buildTableGrid(
        context,
        orders,
        submittedTables,
        statuses,
        processingOrders,
        tableNumbers,
        isLoadingStatuses: isLoadingStatuses,
        statusError: statusError,
      );
    });
  }

  Widget _buildTableGrid(
    BuildContext context,
    Map<int, KotTableOrder> orders,
    Set<int> submittedTables,
    Map<int, TableStatusData> statuses,
    Map<int, ProcessingOrderData> processingOrders,
    List<int> tableNumbers, {
    required bool isLoadingStatuses,
    required String? statusError,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 600
            ? 2
            : constraints.maxWidth < 1000
            ? 3
            : 5;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a Table',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose a free table or open an occupied table.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              if (isLoadingStatuses) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(),
              ],
              if (statusError != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        statusError,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    TextButton(
                      onPressed: controller.getTableStatuses,
                      child: const Text('Retry Status'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refreshKotTables,
                  child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: tableNumbers.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: columns == 2 ? 1.05 : 1.18,
                    ),
                    itemBuilder: (context, index) {
                      final tableNumber = tableNumbers[index];
                      final order = orders[tableNumber];
                      final status = statuses[tableNumber];
                      return _TableTile(
                        tableNumber: tableNumber,
                        order: order,
                        localOrderSubmitted: submittedTables.contains(
                          tableNumber,
                        ),
                        processingOrder: processingOrders[tableNumber],
                        apiStatus: status,
                        onTakeOrder: order != null
                            ? () => controller.continueKotTable(tableNumber)
                            : () => _takeOrder(tableNumber),
                        onOpenOrder:
                            (order != null &&
                                    submittedTables.contains(tableNumber)) ||
                                status?.occupied == true
                            ? () => controller.showKotTableDetails(tableNumber)
                            : null,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _takeOrder(int tableNumber) {
    final staffController = Get.isRegistered<StaffController>()
        ? Get.find<StaffController>()
        : null;
    controller.takeKotTable(
      tableNumber,
      staffName: staffController?.selectedStaffName ?? 'Staff',
      staffId: staffController?.selectedStaff.value?.id,
    );
    onOpenOrder?.call();
  }
}

class _ProcessingTableDetailsView extends StatelessWidget {
  const _ProcessingTableDetailsView({
    required this.tableNumber,
    required this.data,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onContinue,
  });

  final int? tableNumber;
  final ProcessingOrderData? data;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final order = data?.order;
    if (order == null) {
      return _TableLoadState(
        icon: Icons.receipt_long_outlined,
        message: error ?? 'No processing order was found.',
        actionLabel: 'Retry',
        onAction: onRetry ?? () {},
      );
    }
    final products = order.products ?? const <ProcessingProduct>[];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Table ${tableNumber ?? order.tableId ?? ''} Order',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Continue Order'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _DetailRow(
                  label: 'Order',
                  value: order.orderId ?? '${order.id ?? '-'}',
                ),
                _DetailRow(
                  label: 'Taken by',
                  value: order.staffName ?? 'Staff',
                ),
                _DetailRow(
                  label: 'Status',
                  value: order.status?.capitalize ?? 'Processing',
                ),
                _DetailRow(label: 'Items', value: '${products.length}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Order Items',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: products.isEmpty
                ? const Center(
                    child: Text(
                      'No products were returned for this order.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    itemCount: products.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final product = products[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.yellowLight,
                          foregroundColor: AppColors.yellowDark,
                          child: Text('${product.quantity ?? 0}'),
                        ),
                        title: Text(
                          product.productName ?? 'Unnamed product',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.black,
                                fontWeight: .w700,
                              ),
                        ),
                        subtitle: Text(product.unit ?? ''),
                        trailing: Text(
                          '${product.quantity ?? 0} x',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TableLoadState extends StatelessWidget {
  const _TableLoadState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _KotTableDetailsView extends StatelessWidget {
  const _KotTableDetailsView({required this.order, required this.onContinue});

  final KotTableOrder order;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Table ${order.tableNumber} Order',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Continue Order'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _DetailRow(label: 'Taken by', value: order.staffName),
                _DetailRow(label: 'Opened', value: _time(order.openedAt)),
                _DetailRow(label: 'Items', value: '${order.itemCount}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Order Items',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: order.items.isEmpty
                ? const Center(
                    child: Text(
                      'No products have been added yet.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    itemCount: order.items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final item = order.items[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.yellowLight,
                          foregroundColor: AppColors.yellowDark,
                          child: Text('${item.quantity}'),
                        ),
                        title: Text(item.product.name),
                        subtitle: Text(item.displayUnit),
                        trailing: Text(
                          '${item.quantity} x',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _time(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)} '
        '${two(value.hour)}:${two(value.minute)}';
  }
}

class _TableTile extends StatelessWidget {
  const _TableTile({
    required this.tableNumber,
    required this.order,
    required this.localOrderSubmitted,
    required this.processingOrder,
    required this.apiStatus,
    required this.onTakeOrder,
    required this.onOpenOrder,
  });

  final int tableNumber;
  final KotTableOrder? order;
  final bool localOrderSubmitted;
  final ProcessingOrderData? processingOrder;
  final TableStatusData? apiStatus;
  final VoidCallback onTakeOrder;
  final VoidCallback? onOpenOrder;

  @override
  Widget build(BuildContext context) {
    final apiOccupied = apiStatus?.occupied == true;
    final occupied = (order != null && localOrderSubmitted) || apiOccupied;
    final statusLabel = order != null && localOrderSubmitted
        ? 'Occupied'
        : apiStatus?.displayStatus ?? (occupied ? 'Occupied' : 'Free');
    final hasOrder = occupied;
    final remoteOrder = processingOrder?.order;
    final remoteItemCount =
        (remoteOrder?.products ?? const <ProcessingProduct>[]).fold<int>(
          0,
          (sum, item) => sum + (item.quantity ?? 0),
        );
    final remoteStaffName = remoteOrder?.staffName?.trim();
    return Material(
      color: occupied ? const Color(0xFFFFF7ED) : AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: occupied ? onOpenOrder : onTakeOrder,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: occupied ? AppColors.warning : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.table_restaurant_outlined,
                    color: occupied
                        ? AppColors.warning
                        : AppColors.textSecondary,
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      statusLabel,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: occupied ? AppColors.warning : AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Table $tableNumber',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                occupied && order != null
                    ? '${order!.itemCount} items - ${order!.staffName}'
                    : occupied && apiOccupied
                    ? remoteOrder == null
                          ? 'Order details'
                          : '$remoteItemCount items - '
                                '${remoteStaffName?.isNotEmpty == true ? remoteStaffName : 'Staff'}'
                    : 'Available for a new order',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              if (hasOrder)
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'View details',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onTakeOrder,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(38),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Take Order'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
