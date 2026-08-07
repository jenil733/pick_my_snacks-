import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/core/services/local_storage.dart';
import 'package:pick_my_snacks/src/core/utils/navigation/approutes.dart';
import 'package:pick_my_snacks/src/data/model/get_staff.dart';
import 'package:pick_my_snacks/src/presentation/controller/staff/staff_controller.dart';

class StaffMenu extends StatefulWidget {
  const StaffMenu({super.key});

  @override
  State<StaffMenu> createState() => _StaffMenuState();
}

class _StaffMenuState extends State<StaffMenu>
    with SingleTickerProviderStateMixin {
  final _buttonKey = GlobalKey();
  late final AnimationController _shineController;

  StaffController get _controller => Get.isRegistered<StaffController>()
      ? Get.find<StaffController>()
      : Get.put(StaffController());

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(count: 10);
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Obx(
      () => Material(
        key: _buttonKey,
        color: Colors.transparent,
        child: InkWell(
          onTap: controller.isLoading.value ? null : _openMenu,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 145,
            height: 42,
            constraints: const BoxConstraints(maxWidth: 145),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: .28)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: .18),
                  Colors.white.withValues(alpha: .07),
                  AppColors.primary.withValues(alpha: .10),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: .08),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _shineController,
                    builder: (context, child) {
                      final position = Curves.easeInOutCubic.transform(
                        _shineController.value,
                      );
                      return FractionalTranslation(
                        translation: Offset(-1 + (position * 2.8), 0),
                        child: Transform.rotate(
                          angle: -.24,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 28,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0),
                                    Colors.white.withValues(alpha: .34),
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (controller.isLoading.value)
                        const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(
                          Icons.badge_outlined,
                          color: Colors.white,
                          size: 19,
                        ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          controller.selectedStaffName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(color: Color(0x66000000), blurRadius: 5),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
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

  Future<void> _openMenu() async {
    final controller = _controller;
    await controller.getStaff();
    if (!mounted) return;

    final button = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (button == null || overlay == null) return;

    final topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight = button.localToGlobal(
      button.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );
    final position = RelativeRect.fromRect(
      Rect.fromPoints(topLeft, bottomRight),
      Offset.zero & overlay.size,
    );

    final choice = await showMenu<_StaffChoice>(
      context: context,
      position: position,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 340),
      items: _menuItems(controller),
    );
    if (!mounted || choice == null) return;

    if (choice.staff != null) {
      await controller.selectStaff(choice.staff!);
      return;
    }
    if (choice.action == _StaffAction.retry) {
      await _openMenu();
    } else if (choice.action == _StaffAction.logout) {
      await _logout();
    }
  }

  List<PopupMenuEntry<_StaffChoice>> _menuItems(StaffController controller) {
    final items = <PopupMenuEntry<_StaffChoice>>[
      const PopupMenuItem<_StaffChoice>(
        enabled: false,
        height: 36,
        child: Text(
          'Select staff',
          style: TextStyle(
            color: AppColors.yellowDark,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ];

    final error = controller.errorMessage.value;
    if (error != null) {
      items.add(
        PopupMenuItem<_StaffChoice>(
          value: const _StaffChoice.action(_StaffAction.retry),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.refresh_rounded),
            title: const Text('Retry'),
            subtitle: Text(error, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ),
      );
    } else if (controller.staff.isEmpty) {
      items.add(
        const PopupMenuItem<_StaffChoice>(
          enabled: false,
          child: Text(
            'No staff members found.',
            style: TextStyle(color: AppColors.yellowDark),
          ),
        ),
      );
    } else {
      for (final staff in controller.staff) {
        items.add(
          PopupMenuItem<_StaffChoice>(
            value: _StaffChoice.staff(staff),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.yellowLight,
                foregroundColor: AppColors.yellowDark,
                child: Icon(Icons.person_outline_rounded),
              ),
              title: Text(
                staff.name?.trim().isNotEmpty == true
                    ? staff.name!.trim()
                    : 'Unnamed staff',
                style: const TextStyle(
                  color: AppColors.yellowDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                staff.designation?.trim().isNotEmpty == true
                    ? staff.designation!.trim()
                    : 'Staff member',
                style: const TextStyle(color: AppColors.yellowDark),
              ),
            ),
          ),
        );
      }
    }

    items
      ..add(const PopupMenuDivider())
      ..add(
        const PopupMenuItem<_StaffChoice>(
          value: _StaffChoice.action(_StaffAction.logout),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ),
      );
    return items;
  }

  Future<void> _logout() async {
    if (Get.isRegistered<LocalStorageService>()) {
      final storage = Get.find<LocalStorageService>();
      await Future.wait([
        storage.remove(ApiService.authTokenKey),
        storage.remove(LocalStorageService.selectedStaffIdKey),
      ]);
    }
    await _controller.clearSelection();
    Get.offAllNamed(AppRoutes.login);
  }
}

enum _StaffAction { retry, logout }

class _StaffChoice {
  const _StaffChoice.staff(this.staff) : action = null;
  const _StaffChoice.action(this.action) : staff = null;

  final StaffData? staff;
  final _StaffAction? action;
}
