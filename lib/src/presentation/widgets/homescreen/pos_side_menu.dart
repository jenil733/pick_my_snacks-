import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/core/services/local_storage.dart';
import 'package:pick_my_snacks/src/core/utils/navigation/approutes.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/staff/staff_controller.dart';

class PosSideMenu extends StatelessWidget {
  const PosSideMenu({required this.controller, this.onFlowSelected, super.key});

  final HomeController controller;
  final ValueChanged<PosFlow>? onFlowSelected;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 14),
              child: Row(
                children: [
                  Icon(
                    Icons.point_of_sale_rounded,
                    color: AppColors.yellowDark,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'POS Menu',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'CATEGORY',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Obx(
              () => _MenuItem(
                icon: Icons.receipt_long_outlined,
                label: 'Billing',
                selected: controller.flow.value == PosFlow.billing,
                onTap: () => _selectFlow(context, PosFlow.billing),
              ),
            ),
            Obx(
              () => _MenuItem(
                icon: Icons.soup_kitchen_outlined,
                label: 'KOT',
                selected: controller.flow.value == PosFlow.kot,
                onTap: () => _selectFlow(context, PosFlow.kot),
              ),
            ),
            Obx(
              () => _MenuItem(
                icon: Icons.takeout_dining_outlined,
                label: 'Take Away',
                selected: controller.flow.value == PosFlow.takeAway,
                onTap: () => _selectFlow(context, PosFlow.takeAway),
              ),
            ),
            _MenuItem(
              icon: Icons.print_outlined,
              label: 'Printer Settings',
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(AppRoutes.printerSettings);
              },
            ),
            _MenuItem(
              icon: Icons.logout_rounded,
              label: 'Logout',
              foregroundColor: AppColors.error,
              onTap: () => _logout(context),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _selectFlow(BuildContext context, PosFlow flow) {
    controller.selectFlow(flow);
    onFlowSelected?.call(flow);
    Navigator.pop(context);
  }

  Future<void> _logout(BuildContext context) async {
    Navigator.pop(context);
    if (Get.isRegistered<LocalStorageService>()) {
      final storage = Get.find<LocalStorageService>();
      await Future.wait([
        storage.remove(ApiService.authTokenKey),
        storage.remove(LocalStorageService.selectedStaffIdKey),
      ]);
    }
    if (Get.isRegistered<StaffController>()) {
      await Get.find<StaffController>().clearSelection();
    }
    Get.offAllNamed(AppRoutes.login);
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      selectedColor: AppColors.yellowDark,
      selectedTileColor: AppColors.yellowLight,
      iconColor: foregroundColor,
      textColor: foregroundColor,
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: selected ? const Icon(Icons.check_rounded) : null,
      onTap: onTap,
    );
  }
}
