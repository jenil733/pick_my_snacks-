import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/texthelper.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/bill_summary_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/cart_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/held_bills_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/products_panel.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(controller: controller),
            Expanded(
              child: Padding(
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
          ],
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
          const _AnimatedGlassTitle(),
          Positioned(
            right: 18,
            child: Row(
              children: [
                const StaffMenu(),
                const SizedBox(width: 10),
                Obx(
                  () => _HeldBillsButton(
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
                Icons.pause_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 7),
              Text('Held Bills', style: TextHelper.whiteButton),
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

class _AnimatedGlassTitle extends StatefulWidget {
  const _AnimatedGlassTitle();

  @override
  State<_AnimatedGlassTitle> createState() => _AnimatedGlassTitleState();
}

class _AnimatedGlassTitleState extends State<_AnimatedGlassTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 300,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: Colors.white.withValues(alpha: .18)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: .14),
                  AppColors.primary.withValues(alpha: .10),
                  Colors.white.withValues(alpha: .05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .18),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Positioned(
                      left: -80 + (_controller.value * 420),
                      top: -35,
                      child: Transform.rotate(
                        angle: -.28,
                        child: Container(
                          width: 44,
                          height: 135,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: .30),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Pick My Snacks',
                        style: TextHelper.appBarTitle,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                      ),
                      const SizedBox(height: 1),
                      Text('Billing', style: TextHelper.appBarSubtitle),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
