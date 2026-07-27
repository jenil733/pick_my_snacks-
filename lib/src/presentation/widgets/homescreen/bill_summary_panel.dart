import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/app_toast.dart';
import 'package:pick_my_snacks/src/core/utils/helper/texthelper.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/staff/staff_controller.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/common_widgets.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/payment_method_dropdown.dart';
import 'package:pick_my_snacks/src/services/receipt_printer_service.dart';

class BillSummaryPanel extends StatelessWidget {
  const BillSummaryPanel({required this.controller, this.onNewBill, super.key});

  final HomeController controller;
  final VoidCallback? onNewBill;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: Column(
        children: [
          const SectionHeader(title: 'Bill Summary'),
          const Divider(height: 1),
          Expanded(
            child: Obx(
              () => ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  _totalsCard(),
                  const SizedBox(height: 12),
                  _totalAmountStrip(),
                  const SizedBox(height: 12),
                  PaymentMethodDropdown(controller: controller),
                  const SizedBox(height: 18),
                  Text('Items in Bill', style: TextHelper.bodySemiBold),
                  const SizedBox(height: 8),
                  if (controller.cart.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 42,
                            color: AppColors.divider,
                          ),
                          const SizedBox(height: 9),
                          Text('No items added', style: TextHelper.caption),
                        ],
                      ),
                    )
                  else
                    ...controller.cart.map(_billItemRow),
                  const Divider(height: 24),
                ],
              ),
            ),
          ),
          Obx(
            () => Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed:
                          controller.isSavingOrder.value ||
                              controller.isHoldingOrder.value
                          ? null
                          : () =>
                                startNewBill(controller, onStarted: onNewBill),
                      icon: const Icon(Icons.note_add_outlined, size: 19),
                      label: const Text('New Bill'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          controller.cart.isEmpty ||
                              controller.isHoldingOrder.value
                          ? null
                          : () => holdBill(context, controller),
                      icon: const Icon(
                        Icons.pause_circle_outline_rounded,
                        size: 18,
                      ),
                      label: Text(
                        controller.isHoldingOrder.value
                            ? 'Holding Order...'
                            : 'Hold Bill',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          controller.cart.isEmpty ||
                              controller.isSavingOrder.value
                          ? null
                          : () => printReceipt(context, controller),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        disabledBackgroundColor: AppColors.divider,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            controller.isSavingOrder.value
                                ? 'Saving Order...'
                                : 'Print Receipt',
                            style: TextHelper.whiteButton,
                          ),
                          const Spacer(),
                          Text(
                            money(controller.total),
                            style: TextHelper.whiteButton,
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.print_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _summaryRow(
            label: 'Items (${controller.cart.length})',
            value: money(controller.subtotal),
          ),
          _summaryRow(
            label: 'Discount',
            value: money(0),
            trailing: const Icon(
              Icons.edit_outlined,
              size: 15,
              color: AppColors.textSecondary,
            ),
          ),
          _summaryRow(label: 'GST', value: money(controller.tax)),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: TextHelper.body),
          if (trailing != null) ...[const SizedBox(width: 6), trailing],
          const Spacer(),
          Text(value, style: TextHelper.bodySemiBold),
        ],
      ),
    );
  }

  Widget _totalAmountStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text('Total Amount', style: TextHelper.totalAmount),
          const Spacer(),
          Text(money(controller.total), style: TextHelper.totalAmountValue),
        ],
      ),
    );
  }

  Widget _billItemRow(CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.product.name} ${item.displayUnit}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextHelper.captionText,
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              '×${item.quantity}',
              textAlign: TextAlign.center,
              style: TextHelper.captionText,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 66,
            child: Text(
              money(item.total),
              textAlign: TextAlign.right,
              style: TextHelper.captionText,
            ),
          ),
        ],
      ),
    );
  }
}

void startNewBill(HomeController controller, {VoidCallback? onStarted}) {
  controller.startNewBill();
  onStarted?.call();
}

Future<void> holdBill(BuildContext context, HomeController controller) async {
  if (controller.cart.isEmpty) return;
  final staffController = Get.isRegistered<StaffController>()
      ? Get.find<StaffController>()
      : null;
  final bill = await controller.holdOrder(
    staffId: staffController?.selectedStaff.value?.id,
  );
  if (!context.mounted) return;
  if (bill == null) {
    _showPrinterToast(
      context,
      controller.holdOrderError.value ?? 'Unable to hold the order.',
    );
    return;
  }
  AppToast.show(context, 'Bill #${bill.id} held successfully.');
}

Future<void> printReceipt(
  BuildContext context,
  HomeController controller,
) async {
  final staffController = Get.isRegistered<StaffController>()
      ? Get.find<StaffController>()
      : null;
  final selectedStaffId = staffController?.selectedStaff.value?.id;
  final orderSaved = await controller.saveOrder(staffId: selectedStaffId);
  if (!context.mounted) return;
  if (!orderSaved) {
    _showPrinterToast(
      context,
      controller.saveOrderError.value ?? 'Unable to save the order.',
    );
    return;
  }

  final items = controller.cart.map((item) => item.copy()).toList();
  final subtotal = controller.subtotal;
  final tax = controller.tax;
  final total = controller.total;
  final printerService = ReceiptPrinterService();

  try {
    // The Android plugin does not complete connectionStatus when permission is
    // denied, so permission must always be checked before connection status.
    final hasPermission = await printerService.isBluetoothPermissionGranted;
    final needsConnection = !hasPermission || !await printerService.isConnected;
    AppToast.dismiss();
    if (needsConnection) {
      if (!context.mounted) return;
      final connected = await showDialog<bool>(
        context: context,
        builder: (_) =>
            _PrinterConnectionDialog(printerService: printerService),
      );
      if (connected != true) return;
    }

    if (!context.mounted) return;
    await printerService.printBluetoothReceipt(
      items: items,
      subtotal: subtotal,
      tax: tax,
      total: total,
      orderNumber: controller.savedOrderNumber.value ?? '',
      paperSize: ReceiptPaperSize.mm58,
    );
    if (!context.mounted) return;
    AppToast.show(context, 'Receipt sent to the printer.');
  } on ReceiptPrinterException catch (error) {
    if (!context.mounted) return;
    AppToast.dismiss();
    _showPrinterToast(context, error.message);
  } catch (_) {
    if (!context.mounted) return;
    AppToast.dismiss();
    _showPrinterToast(context, 'The printer is not connected.');
  }
}

void _showPrinterToast(BuildContext context, String message) {
  AppToast.error(context, message);
}

class _PrinterConnectionDialog extends StatefulWidget {
  const _PrinterConnectionDialog({required this.printerService});

  final ReceiptPrinterService printerService;

  @override
  State<_PrinterConnectionDialog> createState() =>
      _PrinterConnectionDialogState();
}

class _PrinterConnectionDialogState extends State<_PrinterConnectionDialog> {
  List<ThermalPrinterDevice> _printers = const [];
  String _message = 'Checking Bluetooth...';
  bool _isLoading = true;
  bool _permissionDenied = false;
  String? _connectingAddress;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
      _message = 'Checking Bluetooth...';
      _printers = const [];
    });

    try {
      var hasPermission =
          await widget.printerService.isBluetoothPermissionGranted;
      if (!hasPermission) {
        hasPermission = await widget.printerService
            .requestBluetoothPermission();
      }
      if (!mounted) return;
      if (!hasPermission) {
        setState(() {
          _isLoading = false;
          _permissionDenied = true;
          _message =
              'Nearby devices permission is required to find and connect '
              'the thermal printer.';
        });
        return;
      }

      final enabled = await widget.printerService.isBluetoothEnabled;
      if (!mounted) return;
      if (!enabled) {
        setState(() {
          _isLoading = false;
          _message = 'Turn on Bluetooth, then tap Refresh.';
        });
        return;
      }

      final printers = await widget.printerService.pairedPrinters;
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _printers = printers;
        _message = printers.isEmpty
            ? 'No paired devices found. Pair the printer in your device '
                  'Bluetooth settings, then tap Refresh.'
            : 'Select your paired thermal printer.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _message = 'Unable to read Bluetooth devices. Tap Refresh to retry.';
      });
    }
  }

  Future<void> _openSettings() async {
    await widget.printerService.openPermissionSettings();
    if (!mounted) return;
    setState(() {
      _message = 'Allow Nearby devices, return here, then tap Refresh.';
    });
  }

  Future<void> _connect(ThermalPrinterDevice printer) async {
    setState(() {
      _connectingAddress = printer.address;
      _message = 'Connecting to ${printer.name}...';
    });

    try {
      final connected = await widget.printerService.connect(printer);
      if (!mounted) return;
      if (connected) {
        Navigator.of(context).pop(true);
        return;
      }

      setState(() {
        _connectingAddress = null;
        _message =
            'Could not connect to ${printer.name}. Make sure it is on and '
            'not connected to another device.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connectingAddress = null;
        _message = 'Connection failed. Check the printer and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnecting = _connectingAddress != null;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.print_rounded),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Connect thermal printer',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The printer is not connected.'),
            const SizedBox(height: 6),
            Text(_message, style: TextHelper.caption),
            if (_isLoading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_printers.isNotEmpty) ...[
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _printers.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final printer = _printers[index];
                    final connecting = _connectingAddress == printer.address;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        child: Icon(Icons.print_outlined),
                      ),
                      title: Text(printer.name),
                      subtitle: Text(printer.address),
                      trailing: connecting
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      enabled: !isConnecting,
                      onTap: () => _connect(printer),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_permissionDenied)
          TextButton.icon(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Open Settings'),
          ),
        TextButton(
          onPressed: isConnecting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton.icon(
          onPressed: _isLoading || isConnecting ? null : _loadPrinters,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ],
    );
  }
}
