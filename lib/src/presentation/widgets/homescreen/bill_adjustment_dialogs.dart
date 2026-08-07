import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/texthelper.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';

const _adjustmentColor = AppColors.yellow;
const _adjustmentTextColor = AppColors.yellowDark;

Future<void> showDiscountDialog(
  BuildContext context,
  HomeController controller,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _DiscountDialog(controller: controller),
  );
}

Future<void> showChargeDialog(BuildContext context, HomeController controller) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ChargeDialog(controller: controller),
  );
}

class BillAdjustmentButtons extends StatelessWidget {
  const BillAdjustmentButtons({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AdjustmentButton(
          label: 'Discount',
          icon: Icons.discount_outlined,
          onPressed: () => showDiscountDialog(context, controller),
        ),
        const SizedBox(width: 6),
        _AdjustmentButton(
          label: 'Charge',
          icon: Icons.request_quote_outlined,
          onPressed: () => showChargeDialog(context, controller),
        ),
      ],
    );
  }
}

class _AdjustmentButton extends StatelessWidget {
  const _AdjustmentButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 15),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: _adjustmentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          textStyle: TextHelper.whiteButton,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
      ),
    );
  }
}

class _DiscountDialog extends StatefulWidget {
  const _DiscountDialog({required this.controller});

  final HomeController controller;

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _offerController;
  late final TextEditingController _reasonController;
  late String _type;

  @override
  void initState() {
    super.initState();
    final controller = widget.controller;
    _type = controller.discountType.value == 'percentage'
        ? 'percentage'
        : 'flat';
    _amountController = TextEditingController(
      text: controller.discountType.value == 'none'
          ? ''
          : _numberText(controller.discountValue.value),
    );
    _offerController = TextEditingController(
      text: controller.discountOffer.value,
    );
    _reasonController = TextEditingController(
      text: controller.discountReason.value,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _offerController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _apply() {
    if (!_formKey.currentState!.validate()) return;
    widget.controller.applyDiscount(
      type: _type,
      value: double.parse(_amountController.text.trim()),
      offer: _offerController.text,
      reason: _reasonController.text,
    );
    Navigator.of(context).pop();
  }

  void _clear() {
    widget.controller.clearDiscount();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _AdjustmentDialogShell(
      title: 'Add Discount',
      icon: Icons.discount_outlined,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel('DISCOUNT TYPE'),
            const SizedBox(height: 7),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _TypeChoice(
                  label: 'Flat (₹)',
                  selected: _type == 'flat',
                  onTap: () => setState(() => _type = 'flat'),
                ),
                _TypeChoice(
                  label: 'Percentage (%)',
                  selected: _type == 'percentage',
                  onTap: () => setState(() => _type = 'percentage'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _FieldLabel('AMOUNT (₹)'),
            const SizedBox(height: 7),
            _AmountField(
              key: const ValueKey('discount-amount'),
              controller: _amountController,
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                if (amount == null || amount <= 0) {
                  return 'Enter an amount greater than zero.';
                }
                if (_type == 'percentage' && amount > 100) {
                  return 'Percentage cannot be more than 100.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const _FieldLabel('OFFER (OPTIONAL)'),
            const SizedBox(height: 7),
            _TextField(
              controller: _offerController,
              hintText: 'e.g. Diwali Offer',
            ),
            const SizedBox(height: 16),
            const _FieldLabel('REASON (OPTIONAL)'),
            const SizedBox(height: 7),
            _TextField(
              controller: _reasonController,
              hintText: 'Enter reason (optional)',
            ),
          ],
        ),
      ),
      actions: [
        if (widget.controller.discountType.value != 'none')
          TextButton(
            onPressed: _clear,
            style: TextButton.styleFrom(foregroundColor: _adjustmentTextColor),
            child: const Text('Remove'),
          ),
        const Spacer(),
        _CancelButton(onPressed: () => Navigator.of(context).pop()),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _apply,
          style: FilledButton.styleFrom(backgroundColor: _adjustmentColor),
          child: const Text('Apply Discount'),
        ),
      ],
    );
  }
}

class _ChargeDialog extends StatefulWidget {
  const _ChargeDialog({required this.controller});

  final HomeController controller;

  @override
  State<_ChargeDialog> createState() => _ChargeDialogState();
}

class _ChargeDialogState extends State<_ChargeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    final controller = widget.controller;
    _amountController = TextEditingController(
      text: controller.chargeAmount.value <= 0
          ? ''
          : _numberText(controller.chargeAmount.value),
    );
    _reasonController = TextEditingController(
      text: controller.chargeReason.value,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _apply() {
    if (!_formKey.currentState!.validate()) return;
    widget.controller.applyCharge(
      amount: double.parse(_amountController.text.trim()),
      reason: _reasonController.text,
    );
    Navigator.of(context).pop();
  }

  void _clear() {
    widget.controller.clearCharge();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _AdjustmentDialogShell(
      title: 'Add Charge',
      icon: Icons.request_quote_outlined,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel('AMOUNT (₹)'),
            const SizedBox(height: 7),
            _AmountField(
              key: const ValueKey('charge-amount'),
              controller: _amountController,
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                return amount == null || amount <= 0
                    ? 'Enter an amount greater than zero.'
                    : null;
              },
            ),
            const SizedBox(height: 18),
            const _FieldLabel('REASON'),
            const SizedBox(height: 7),
            _TextField(controller: _reasonController, hintText: 'Enter reason'),
          ],
        ),
      ),
      actions: [
        if (widget.controller.chargeAmount.value > 0)
          TextButton(
            onPressed: _clear,
            style: TextButton.styleFrom(foregroundColor: _adjustmentTextColor),
            child: const Text('Remove'),
          ),
        const Spacer(),
        _CancelButton(onPressed: () => Navigator.of(context).pop()),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _apply,
          style: FilledButton.styleFrom(backgroundColor: _adjustmentColor),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _AdjustmentDialogShell extends StatelessWidget {
  const _AdjustmentDialogShell({
    required this.title,
    required this.icon,
    required this.content,
    required this.actions,
  });

  final String title;
  final IconData icon;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _adjustmentColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 54,
                color: _adjustmentColor,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 19),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        title,
                        style: TextHelper.sectionTitle.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
                child: content,
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: actions),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextHelper.bodySemiBold.copyWith(color: _adjustmentTextColor),
    );
  }
}

class _TypeChoice extends StatelessWidget {
  const _TypeChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? _adjustmentTextColor : AppColors.divider,
              size: 19,
            ),
            const SizedBox(width: 6),
            Text(label, style: TextHelper.body),
          ],
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.validator,
    super.key,
  });

  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: _inputDecoration(),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({required this.controller, required this.hintText});

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(hintText: hintText),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(backgroundColor: AppColors.textSecondary),
      child: const Text('Cancel'),
    );
  }
}

InputDecoration _inputDecoration({String? hintText}) {
  return InputDecoration(
    hintText: hintText,
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _adjustmentColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _adjustmentColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _adjustmentColor, width: 2),
    ),
  );
}

String _numberText(double value) {
  return value % 1 == 0 ? value.toInt().toString() : value.toString();
}
