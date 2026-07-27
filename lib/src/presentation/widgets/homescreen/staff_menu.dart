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

class _StaffMenuState extends State<StaffMenu> {
  final _buttonKey = GlobalKey();

  StaffController get _controller => Get.isRegistered<StaffController>()
      ? Get.find<StaffController>()
      : Get.put(StaffController());

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Material(
      key: _buttonKey,
      color: Colors.transparent,
      child: InkWell(
        onTap: controller.isLoading.value ? null : _openMenu,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 42,
          constraints: const BoxConstraints(maxWidth: 180),
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: .16)),
          ),
          child: Obx(
            () => Row(
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
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 340),
      items: _menuItems(controller),
    );
    if (!mounted || choice == null) return;

    if (choice.staff != null) {
      controller.selectStaff(choice.staff!);
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
            color: AppColors.textSecondary,
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
          child: Text('No staff members found.'),
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
                child: Icon(Icons.person_outline_rounded),
              ),
              title: Text(
                staff.name?.trim().isNotEmpty == true
                    ? staff.name!.trim()
                    : 'Unnamed staff',
              ),
              subtitle: Text(
                staff.designation?.trim().isNotEmpty == true
                    ? staff.designation!.trim()
                    : 'Staff member',
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
      await Get.find<LocalStorageService>().remove(ApiService.authTokenKey);
    }
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
