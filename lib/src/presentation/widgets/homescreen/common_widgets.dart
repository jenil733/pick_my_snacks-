import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/texthelper.dart';

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
