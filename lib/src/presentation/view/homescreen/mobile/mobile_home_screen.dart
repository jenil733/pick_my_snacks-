import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/view/homescreen/mobile/mobile_billing_screen.dart';
import 'package:pick_my_snacks/src/presentation/view/homescreen/mobile/mobile_products_screen.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/held_bills_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/common_widgets.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/product_qr_scanner.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/staff_menu.dart';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({required this.controller, super.key});

  final HomeController controller;

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  int _selectedIndex = 0;

  void _select(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      MobileProductsScreen(
        controller: widget.controller,
        onOpenBill: () => _select(1),
      ),
      MobileBillingScreen(
        controller: widget.controller,
        onAddProduct: () => _select(0),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 62,
        backgroundColor: AppColors.navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
        titleSpacing: 8,
        title: const PulsingAppLogo(),
        actions: [
          const StaffMenu(),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Scan product QR',
            onPressed: () => showProductQrScanner(
              context,
              widget.controller,
              onProductAdded: () => _select(1),
            ),
            icon: const Icon(Icons.qr_code_scanner_rounded),
          ),
          Obx(
            () => IconButton(
              tooltip: 'Hold',
              onPressed: () => showHeldBillsPanel(context, widget.controller),
              style: IconButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: .12),
                side: BorderSide(color: Colors.white),
              ),
              icon: Badge(
                isLabelVisible: widget.controller.heldBillCount > 0,
                label: Text('${widget.controller.heldBillCount}'),
                child: const Icon(Icons.pause_circle_filled_rounded, size: 25),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: Obx(
        () => NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: AppColors.yellowLight,
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                color: states.contains(WidgetState.selected)
                    ? AppColors.yellowDark
                    : AppColors.textSecondary,
              ),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                color: states.contains(WidgetState.selected)
                    ? AppColors.yellowDark
                    : AppColors.textSecondary,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _select,
            height: 68,
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.yellowLight,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2_rounded),
                label: 'Products',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: widget.controller.itemCount > 0,
                  label: Text('${widget.controller.itemCount}'),
                  child: const Icon(Icons.receipt_long_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: widget.controller.itemCount > 0,
                  label: Text('${widget.controller.itemCount}'),
                  child: const Icon(Icons.receipt_long_rounded),
                ),
                label: 'Bill',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
