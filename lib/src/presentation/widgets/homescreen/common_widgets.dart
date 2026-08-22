import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/const/appimages.dart';
import 'package:pick_my_snacks/src/core/utils/helper/app_toast.dart';
import 'package:pick_my_snacks/src/core/utils/helper/texthelper.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';

class DashboardPanel extends StatelessWidget {
  const DashboardPanel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PulsingAppLogo extends StatefulWidget {
  const PulsingAppLogo({
    this.width = 112,
    this.height = 56,
    this.canvasSize = 150,
    super.key,
  });

  final double width;
  final double height;
  final double canvasSize;

  @override
  State<PulsingAppLogo> createState() => _PulsingAppLogoState();
}

class _PulsingAppLogoState extends State<PulsingAppLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true, count: 8);
    _scale = Tween<double>(
      begin: .90,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: ClipRect(
            child: OverflowBox(
              minWidth: widget.canvasSize,
              maxWidth: widget.canvasSize,
              minHeight: widget.canvasSize,
              maxHeight: widget.canvasSize,
              child: Image.asset(
                AppImages.appIcon,
                width: widget.canvasSize,
                height: widget.canvasSize,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: TextHelper.sectionTitle)),
          ?trailing,
        ],
      ),
    );
  }
}

class SoftIconButton extends StatelessWidget {
  const SoftIconButton({
    required this.icon,
    required this.onTap,
    this.color = AppColors.primary,
    this.size = 34,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: color.withValues(alpha: .07),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: .22)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({
    required this.path,
    this.size = 48,
    this.padding = 5,
    super.key,
  });

  final String path;
  final double size;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    if (!isNetwork) {
      return SvgPicture.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const _DefaultProductIcon(),
      );
    }

    if (Uri.tryParse(path)?.path.toLowerCase().endsWith('.svg') == true) {
      return SvgPicture.network(
        path,
        fit: BoxFit.contain,
        placeholderBuilder: (_) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorBuilder: (_, _, _) => const _DefaultProductIcon(),
      );
    }

    return Image.network(
      path,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const _DefaultProductIcon(),
    );
  }
}

class _DefaultProductIcon extends StatelessWidget {
  const _DefaultProductIcon();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.inventory_2_outlined,
        color: AppColors.textSecondary,
        size: 28,
      ),
    );
  }
}

String money(double value) => '₹${value.toStringAsFixed(2)}';

class EditableItemAmount extends StatelessWidget {
  const EditableItemAmount({
    required this.controller,
    required this.item,
    this.width = 38,
    super.key,
  });

  final HomeController controller;
  final CartItem item;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Tap to edit quantity or weight',
      child: InkWell(
        onTap: () => showItemAmountDialog(context, controller, item),
        child: SizedBox(
          width: width,
          height: 28,
          child: Center(
            child: Text(
              _displayAmount(item.editableAmount),
              textAlign: TextAlign.center,
              style: TextHelper.bodySemiBold.copyWith(
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dotted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ExtraItemNoteField extends StatefulWidget {
  const ExtraItemNoteField({
    required this.controller,
    required this.item,
    super.key,
  });

  final HomeController controller;
  final CartItem item;

  @override
  State<ExtraItemNoteField> createState() => _ExtraItemNoteFieldState();
}

class _ExtraItemNoteFieldState extends State<ExtraItemNoteField> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.item.notes);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant ExtraItemNoteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.uniqueId != widget.item.uniqueId ||
        (_textController.text != widget.item.notes && !_focusNode.hasFocus)) {
      _textController.text = widget.item.notes;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textController,
      focusNode: _focusNode,
      onChanged: (value) =>
          widget.controller.updateItemNotes(widget.item, value),
      textInputAction: TextInputAction.done,
      maxLines: 1,
      decoration: const InputDecoration(
        hintText: 'Special mention',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        border: OutlineInputBorder(),
      ),
    );
  }
}

Future<void> showItemAmountDialog(
  BuildContext context,
  HomeController controller,
  CartItem item,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ItemAmountDialog(controller: controller, item: item),
  );
}

class _ItemAmountDialog extends StatefulWidget {
  const _ItemAmountDialog({required this.controller, required this.item});

  final HomeController controller;
  final CartItem item;

  @override
  State<_ItemAmountDialog> createState() => _ItemAmountDialogState();
}

class _ItemAmountDialogState extends State<_ItemAmountDialog> {
  late final TextEditingController _inputController;
  String? error;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController(
      text: _displayAmount(widget.item.editableAmount),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      title: const Text('Edit quantity or weight'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.item.product.name, style: TextHelper.bodySemiBold),
          const SizedBox(height: 12),
          TextField(
            controller: _inputController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Quantity / weight',
              hintText: 'Example: 0.5 for half kilogram',
              errorText: error,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.text,
          ),
          onPressed: () {
            final normalized = _inputController.text.trim().replaceAll(
              ',',
              '.',
            );
            final amount = double.tryParse(normalized);
            if (amount == null || amount <= 0) {
              setState(() {
                error = 'Enter a value greater than 0.';
              });
              return;
            }
            final validationError = widget.controller.setItemAmount(
              widget.item,
              amount,
            );
            if (validationError != null) {
              setState(() {
                error = validationError;
              });
              return;
            }
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

String _displayAmount(double value) {
  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  IconData icon = Icons.help_outline_rounded,
  Color confirmColor = AppColors.primary,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      icon: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: confirmColor.withValues(alpha: .10),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: confirmColor, size: 27),
      ),
      title: Text(title, textAlign: TextAlign.center, style: TextHelper.title),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: TextHelper.poppins,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text('Cancel', style: TextHelper.body),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(backgroundColor: confirmColor),
          child: Text(confirmLabel, style: TextHelper.whiteButton),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> deleteKotTableOrder(
  BuildContext context,
  HomeController controller,
) async {
  final tableId =
      controller.activeTableNumber.value ??
      controller.selectedKotTableNumber.value;
  if (tableId == null) return;
  final confirmed = await showConfirmationDialog(
    context: context,
    title: 'Delete table order?',
    message: 'All items for Table $tableId will be removed.',
    confirmLabel: 'Delete',
    icon: Icons.delete_outline_rounded,
    confirmColor: AppColors.error,
  );
  if (!confirmed || !context.mounted) return;
  final deleted = await controller.deleteActiveKotOrder();
  if (!context.mounted) return;
  if (!deleted) {
    AppToast.error(
      context,
      controller.deleteKotOrderError.value ??
          'Unable to delete the kitchen order.',
    );
    return;
  }
  AppToast.show(context, 'Table $tableId is now free.');
}
