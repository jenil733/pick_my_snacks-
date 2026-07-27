import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/texthelper.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/view/homescreen/mobile/mobile_billing_screen.dart';
import 'package:pick_my_snacks/src/presentation/view/homescreen/mobile/mobile_products_screen.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/held_bills_panel.dart';
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
        onNewBill: () => _select(0),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 62,
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pick My Snacks', style: TextHelper.appBarTitle),
            Text(switch (_selectedIndex) {
              0 => 'Products',
              _ => 'Bill',
            }, style: TextHelper.appBarSearchHint),
          ],
        ),
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
              tooltip: 'Held Bills',
              onPressed: () => showHeldBillsPanel(context, widget.controller),
              icon: Badge(
                isLabelVisible: widget.controller.heldBillCount > 0,
                label: Text('${widget.controller.heldBillCount}'),
                child: const Icon(Icons.pause_circle_outline_rounded),
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
        () => NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _select,
          height: 68,
          backgroundColor: AppColors.surface,
          indicatorColor: const Color(0xFFDBEAFE),
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
    );
  }
}
