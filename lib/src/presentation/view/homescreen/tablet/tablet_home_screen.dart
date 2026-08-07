import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/bill_summary_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/cart_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/common_widgets.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/external_qr_scanner_button.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/held_bills_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/products_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/staff_menu.dart';

class TabletHomeScreen extends StatefulWidget {
  const TabletHomeScreen({required this.controller, super.key});

  final HomeController controller;

  @override
  State<TabletHomeScreen> createState() => _TabletHomeScreenState();
}

class _TabletHomeScreenState extends State<TabletHomeScreen> {
  int _selectedDetail = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 68,
        backgroundColor: AppColors.navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PulsingAppLogo(width: 100, height: 50, canvasSize: 140),
            SizedBox(width: 8),
            Text(
              'Tablet billing',
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          const StaffMenu(),
          const SizedBox(width: 6),
          ExternalQrScannerButton(
            controller: widget.controller,
            onProductAdded: () => setState(() => _selectedDetail = 1),
            showLabel: true,
          ),
          const SizedBox(width: 6),
          Obx(
            () => TextButton.icon(
              onPressed: () => showHeldBillsPanel(context, widget.controller),
              icon: Badge(
                isLabelVisible: widget.controller.heldBillCount > 0,
                label: Text('${widget.controller.heldBillCount}'),
                child: const Icon(Icons.pause_circle_filled_rounded, size: 23),
              ),
              label: const Text('Held'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                flex: 9,
                child: ProductsPanel(controller: widget.controller),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 11,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<int>(
                        segments: [
                          ButtonSegment(
                            value: 0,
                            icon: const Icon(Icons.shopping_cart_outlined),
                            label: Obx(
                              () =>
                                  Text('Cart (${widget.controller.itemCount})'),
                            ),
                          ),
                          const ButtonSegment(
                            value: 1,
                            icon: Icon(Icons.receipt_long_outlined),
                            label: Text('Billing'),
                          ),
                        ],
                        selected: {_selectedDetail},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) {
                          setState(() => _selectedDetail = selection.first);
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedDetail,
                        children: [
                          CartPanel(controller: widget.controller),
                          BillSummaryPanel(controller: widget.controller),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
