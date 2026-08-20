import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/core/services/local_storage.dart';
import 'package:pick_my_snacks/src/core/utils/navigation/approutes.dart';
import 'package:pick_my_snacks/src/data/model/get_staff.dart';
import 'package:pick_my_snacks/src/presentation/controller/staff/staff_controller.dart';

class StaffMenuButtonController {
  Future<void> Function()? _openMenu;

  Future<void> open() async {
    await _openMenu?.call();
  }
}

class StaffMenu extends StatefulWidget {
  const StaffMenu({this.buttonController, this.staffId, super.key});

  final StaffMenuButtonController? buttonController;
  final int? staffId;

  @override
  State<StaffMenu> createState() => _StaffMenuState();
}

class _StaffMenuState extends State<StaffMenu>
    with SingleTickerProviderStateMixin {
  final _buttonKey = GlobalKey();
  late final AnimationController _shineController;
  bool _isMenuOpen = false;

  StaffController get _controller => Get.isRegistered<StaffController>()
      ? Get.find<StaffController>()
      : Get.put(StaffController());

  @override
  void initState() {
    super.initState();
    widget.buttonController?._openMenu = _activate;
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(count: 10);
  }

  @override
  void didUpdateWidget(covariant StaffMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buttonController == widget.buttonController) return;
    oldWidget.buttonController?._openMenu = null;
    widget.buttonController?._openMenu = _activate;
  }

  @override
  void dispose() {
    widget.buttonController?._openMenu = null;
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Obx(() {
      String displayName = controller.selectedStaffName;
      if (widget.staffId != null) {
        final matches = controller.staff.where((s) => s.id == widget.staffId);
        if (matches.isNotEmpty) {
          final name = matches.first.name?.trim();
          if (name != null && name.isNotEmpty) {
            displayName = name;
          }
        }
      }

      return Material(
        key: _buttonKey,
        color: Colors.transparent,
        child: InkWell(
          onTap: controller.isLoading.value ? null : _activate,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 120,
            height: 42,
            constraints: const BoxConstraints(maxWidth: 120),
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
                          displayName,
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
      );
    });
  }

  Future<void> _activate() async {
    if (_controller.isLoading.value || _isMenuOpen) return;
    _isMenuOpen = true;
    try {
      await _openMenu();
    } finally {
      _isMenuOpen = false;
    }
  }

  Future<void> _openMenu() async {
    final controller = _controller;
    await controller.getStaff();
    if (!mounted) return;

    final choice = await showDialog<_StaffChoice>(
      context: context,
      builder: (context) => _StaffPickerDialog(controller: controller),
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

class _StaffPickerDialog extends StatefulWidget {
  const _StaffPickerDialog({required this.controller});

  final StaffController controller;

  @override
  State<_StaffPickerDialog> createState() => _StaffPickerDialogState();
}

class _StaffPickerDialogState extends State<_StaffPickerDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StaffData> get _filteredStaff {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.controller.staff.toList();

    return widget.controller.staff.where((staff) {
      final id = staff.id?.toString() ?? '';
      final userId = staff.userId?.trim().toLowerCase() ?? '';
      final name = staff.name?.trim().toLowerCase() ?? '';
      return id.contains(query) ||
          userId.contains(query) ||
          name.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.controller.errorMessage.value;
    final filteredStaff = _filteredStaff;

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: const Text(
        'Select staff',
        style: TextStyle(
          color: AppColors.yellowDark,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: 360,
        height: 420,
        child: Column(
          children: [
            TextField(
              key: const Key('staff-search-field'),
              controller: _searchController,
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search by staff ID or name',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: error != null
                  ? Center(
                      child: ListTile(
                        onTap: () => Navigator.pop(
                          context,
                          const _StaffChoice.action(_StaffAction.retry),
                        ),
                        leading: const Icon(Icons.refresh_rounded),
                        title: const Text('Retry'),
                        subtitle: Text(
                          error,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                  : filteredStaff.isEmpty
                  ? Center(
                      child: Text(
                        widget.controller.staff.isEmpty
                            ? 'No staff members found.'
                            : 'No staff matches your search.',
                        style: const TextStyle(color: AppColors.yellowDark),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredStaff.length,
                      itemBuilder: (context, index) {
                        final staff = filteredStaff[index];
                        final designation =
                            staff.designation?.trim().isNotEmpty == true
                            ? staff.designation!.trim()
                            : 'Staff member';
                        final staffId = staff.id?.toString();
                        return ListTile(
                          onTap: () =>
                              Navigator.pop(context, _StaffChoice.staff(staff)),
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
                            staffId == null
                                ? designation
                                : 'ID: $staffId  •  $designation',
                            style: const TextStyle(color: AppColors.yellowDark),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(
            context,
            const _StaffChoice.action(_StaffAction.logout),
          ),
          icon: const Icon(Icons.logout_rounded, color: AppColors.error),
          label: const Text('Logout', style: TextStyle(color: AppColors.error)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

enum _StaffAction { retry, logout }

class _StaffChoice {
  const _StaffChoice.staff(this.staff) : action = null;
  const _StaffChoice.action(this.action) : staff = null;

  final StaffData? staff;
  final _StaffAction? action;
}
