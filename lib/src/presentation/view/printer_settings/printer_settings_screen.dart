import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/app_toast.dart';
import 'package:pick_my_snacks/src/printing/printer_manager.dart';
import 'package:pick_my_snacks/src/printing/printer_settings_model.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  PrinterManager get _manager => Get.find<PrinterManager>();

  final Set<PrinterRole> _testing = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Settings'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Scan printers',
            onPressed: () => _choosePrinter(PrinterRole.billing),
            icon: const Icon(Icons.bluetooth_searching_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PrinterAssignment(
              role: PrinterRole.billing,
              printer: _manager.printerFor(PrinterRole.billing),
              isTesting: _testing.contains(PrinterRole.billing),
              onChange: () => _choosePrinter(PrinterRole.billing),
              onTest: () => _testPrinter(PrinterRole.billing),
            ),
            const SizedBox(height: 12),
            _PrinterAssignment(
              role: PrinterRole.takeAway,
              printer: _manager.printerFor(PrinterRole.takeAway),
              isTesting: _testing.contains(PrinterRole.takeAway),
              onChange: () => _choosePrinter(PrinterRole.takeAway),
              onTest: () => _testPrinter(PrinterRole.takeAway),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _choosePrinter(PrinterRole role) async {
    final printer = await showDialog<PrinterSettingsModel>(
      context: context,
      builder: (_) => _PrinterPickerDialog(manager: _manager, role: role),
    );
    if (!mounted || printer == null) return;

    await _manager.assignPrinter(role, printer);
    if (!mounted) return;
    setState(() {});
    AppToast.show(context, '${printer.name} saved as ${role.label}.');
  }

  Future<void> _testPrinter(PrinterRole role) async {
    if (_testing.contains(role)) return;
    setState(() => _testing.add(role));
    try {
      await _manager.testPrint(role);
      if (!mounted) return;
      AppToast.show(context, 'Test print sent to ${role.label}.');
    } on PrinterManagerException catch (error) {
      if (!mounted) return;
      AppToast.error(context, error.message);
    } finally {
      if (mounted) setState(() => _testing.remove(role));
    }
  }
}

class _PrinterAssignment extends StatelessWidget {
  const _PrinterAssignment({
    required this.role,
    required this.printer,
    required this.isTesting,
    required this.onChange,
    required this.onTest,
  });

  final PrinterRole role;
  final PrinterSettingsModel? printer;
  final bool isTesting;
  final VoidCallback onChange;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.print_outlined, color: AppColors.yellowDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  role.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            printer?.name ?? 'No printer selected',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          Text(
            printer == null
                ? 'Tap Change Printer to scan paired devices.'
                : '${printer!.connectionType.label}  ${printer!.address}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onChange,
                  icon: const Icon(Icons.bluetooth_searching_rounded),
                  label: Text(
                    printer == null ? 'Select Printer' : 'Change Printer',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: printer == null || isTesting ? null : onTest,
                  icon: isTesting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print_rounded),
                  label: Text(isTesting ? 'Printing...' : 'Test Print'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrinterPickerDialog extends StatefulWidget {
  const _PrinterPickerDialog({required this.manager, required this.role});

  final PrinterManager manager;
  final PrinterRole role;

  @override
  State<_PrinterPickerDialog> createState() => _PrinterPickerDialogState();
}

class _PrinterPickerDialogState extends State<_PrinterPickerDialog> {
  List<PrinterSettingsModel> _printers = const [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final printers = await widget.manager.scanPrinters();
      if (!mounted) return;
      setState(() {
        _printers = printers;
        _loading = false;
        if (printers.isEmpty) {
          _error =
              'No paired printers found. Pair a printer in Bluetooth '
              'settings, then scan again.';
        }
      });
    } on PrinterManagerException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select ${widget.role.label}'),
      content: SizedBox(
        width: 440,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  if (_printers.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _printers.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final printer = _printers[index];
                          return ListTile(
                            leading: const Icon(Icons.print_outlined),
                            title: Text(printer.name),
                            subtitle: Text(printer.address),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.pop(context, printer),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton.icon(
          onPressed: _loading ? null : _scan,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Scan Again'),
        ),
      ],
    );
  }
}
