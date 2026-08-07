import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/texthelper.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/view/homescreen/kot_tables_view.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/bill_summary_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/cart_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/external_qr_scanner_button.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/held_bills_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/notification_button.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/products_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/pos_side_menu.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/staff_menu.dart';
import 'package:pick_my_snacks/src/presentation/view/homescreen/mobile/mobile_home_screen.dart';
import 'package:pick_my_snacks/src/presentation/view/homescreen/tablet/tablet_home_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return MobileHomeScreen(controller: controller);
        }
        if (constraints.maxWidth < 1100) {
          return TabletHomeScreen(controller: controller);
        }
        return _DesktopHomeScreen(controller: controller);
      },
    );
  }
}

class _DesktopHomeScreen extends StatelessWidget {
  const _DesktopHomeScreen({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (controller.flow.value == PosFlow.kot &&
            controller.kotStage.value != KotStage.tables) {
          controller.showKotTables();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawer: PosSideMenu(controller: controller),
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(controller: controller),
              Expanded(
                child: Obx(
                  () =>
                      controller.flow.value == PosFlow.kot &&
                          controller.kotStage.value != KotStage.order
                      ? KotTablesView(controller: controller)
                      : Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 29,
                                child: ProductsPanel(controller: controller),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 39,
                                child: CartPanel(controller: controller),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 32,
                                child: BillSummaryPanel(controller: controller),
                              ),
                            ],
                          ),
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.navy,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 14,
            child: Builder(
              builder: (context) => IconButton(
                tooltip: 'Open menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
                style: IconButton.styleFrom(foregroundColor: Colors.white),
                icon: const Icon(Icons.menu_rounded, size: 28),
              ),
            ),
          ),
          Obx(
            () => Text(
              controller.flow.value == PosFlow.kot
                  ? controller.kotStage.value == KotStage.tables
                        ? 'KOT Tables'
                        : controller.kotStage.value == KotStage.details
                        ? 'Table ${controller.selectedKotTableNumber.value}'
                        : 'Table ${controller.activeTableNumber.value}'
                  : controller.flow.value == PosFlow.takeAway
                  ? 'Take Away'
                  : 'Billing',
              style: TextHelper.whiteButton.copyWith(fontSize: 18),
            ),
          ),
          Positioned(
            right: 18,
            child: Row(
              children: [
                const StaffMenu(),
                const SizedBox(width: 10),
                ExternalQrScannerButton(
                  controller: controller,
                  showLabel: true,
                ),
                const SizedBox(width: 10),
                const NotificationButton(),
                const SizedBox(width: 10),
                Obx(
                  () => controller.flow.value == PosFlow.takeAway
                      ? const SizedBox.shrink()
                      : _HeldBillsButton(
                          count: controller.heldBillCount,
                          onTap: () => showHeldBillsPanel(context, controller),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeldBillsButton extends StatelessWidget {
  const _HeldBillsButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white.withValues(alpha: .16)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.pause_circle_filled_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 7),
              Text('Held', style: TextHelper.whiteButton),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text('$count', style: TextHelper.whiteButton),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
