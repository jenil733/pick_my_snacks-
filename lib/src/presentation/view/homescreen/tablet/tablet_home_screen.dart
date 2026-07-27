import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/texthelper.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/bill_summary_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/cart_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/held_bills_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/products_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/product_qr_scanner.dart';
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
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pick My Snacks', style: TextHelper.appBarTitle),
            Text('Tablet billing', style: TextHelper.appBarSearchHint),
          ],
        ),
        actions: [
          const StaffMenu(),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Scan product QR',
            onPressed: () => showProductQrScanner(
              context,
              widget.controller,
              onProductAdded: () => setState(() => _selectedDetail = 1),
            ),
            icon: const Icon(Icons.qr_code_scanner_rounded),
          ),
          Obx(
            () => TextButton.icon(
              onPressed: () => showHeldBillsPanel(context, widget.controller),
              icon: Badge(
                isLabelVisible: widget.controller.heldBillCount > 0,
                label: Text('${widget.controller.heldBillCount}'),
                child: const Icon(Icons.pause_circle_outline_rounded),
              ),
              label: const Text('Hold Bills'),
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
                          BillSummaryPanel(
                            controller: widget.controller,
                            onNewBill: () =>
                                setState(() => _selectedDetail = 0),
                          ),
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
