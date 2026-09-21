import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/app_toast.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/staff/staff_controller.dart';

class KotPersonsView extends StatelessWidget {
  const KotPersonsView({required this.controller, this.onOpenOrder, super.key});

  final HomeController controller;
  final VoidCallback? onOpenOrder;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tableNumber = controller.selectedKotTableNumber.value;
      final bills =
          List<KotPersonBill>.from(
              tableNumber == null
                  ? const <KotPersonBill>[]
                  : controller.kotPersonBills[tableNumber] ??
                        const <KotPersonBill>[],
            ).where((bill) => bill.isConfirmed).toList()
            ..sort((a, b) => a.personNumber.compareTo(b.personNumber));
      return LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 600 ? 16.0 : 24.0;
          final cardWidth = constraints.maxWidth < 600
              ? (constraints.maxWidth - horizontalPadding * 2 - 12) / 2
              : 260.0;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              18,
              horizontalPadding,
              32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PersonScreenHeader(
                  tableNumber: tableNumber,
                  personCount: bills.length,
                  onBack: controller.showKotTables,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var index = 0; index < bills.length; index++)
                      SizedBox(
                        width: cardWidth,
                        child: _PersonBillCard(
                          bill: bills[index],
                          colorIndex: index,
                          onTap: () {
                            controller.openKotPersonBill(
                              bills[index].personNumber,
                            );
                            onOpenOrder?.call();
                          },
                          onDelete: () =>
                              _deletePerson(context, bills[index].personNumber),
                        ),
                      ),
                    SizedBox(
                      width: cardWidth,
                      height: 148,
                      child: _AddPersonCard(onTap: () => _addPerson(context)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Future<void> _addPerson(BuildContext context) async {
    debugPrint('[KotAddPerson] Add Person button clicked');
    final staffController = Get.isRegistered<StaffController>()
        ? Get.find<StaffController>()
        : null;
    final selectedStaff = staffController?.selectedStaff.value;
    debugPrint(
      '[KotAddPerson] Selected staff ID: '
      '${selectedStaff?.id}',
    );
    if (selectedStaff?.id == null) {
      AppToast.error(context, 'Please select a staff member.');
      return;
    }
    final personNumber = await controller.addKotPerson(
      staffName: staffController!.selectedStaffName,
      staffId: selectedStaff!.id,
    );
    if (personNumber == null) {
      debugPrint(
        '[KotAddPerson] Person was not created: '
        '${controller.kotAddPersonError.value}',
      );
      return;
    }
    debugPrint('[KotAddPerson] Opening local person number: $personNumber');
    controller.openKotPersonBill(personNumber);
    onOpenOrder?.call();
  }

  Future<void> _deletePerson(BuildContext context, int personNumber) async {
    final deleted = await controller.deleteKotPerson(personNumber);
    if (!context.mounted) return;
    if (!deleted) {
      AppToast.error(
        context,
        controller.kotDeletePersonError.value ??
            'Unable to delete this person.',
      );
    }
  }
}

class _PersonScreenHeader extends StatelessWidget {
  const _PersonScreenHeader({
    required this.tableNumber,
    required this.personCount,
    required this.onBack,
  });

  final int? tableNumber;
  final int personCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: 'Back to tables',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 24),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.table_restaurant_rounded, size: 26),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Table ${tableNumber ?? ''}',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                'Separate bills for each person',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.yellowLight,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.groups_rounded,
                color: AppColors.yellowDark,
                size: 19,
              ),
              const SizedBox(width: 6),
              Text(
                '$personCount ${personCount == 1 ? 'Person' : 'Persons'}',
                style: const TextStyle(
                  color: AppColors.yellowDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonBillCard extends StatelessWidget {
  const _PersonBillCard({
    required this.bill,
    required this.colorIndex,
    required this.onTap,
    required this.onDelete,
  });

  final KotPersonBill bill;
  final int colorIndex;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  static const _colors = <(Color, Color)>[
    (Color(0xFFFFF0A6), Color(0xFFFFCC00)),
    (Color(0xFFFFD7E1), Color(0xFFFF91AB)),
    (Color(0xFFD9F4E5), Color(0xFF70D5A0)),
    (Color(0xFFDDEBFF), Color(0xFF86B5FA)),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _colors[colorIndex % _colors.length];
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colors.$1,
                    foregroundColor: Colors.black,
                    child: Text(
                      '${bill.personNumber}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Person ${bill.personNumber}',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${bill.itemCount} ${bill.itemCount == 1 ? 'item' : 'items'}  •  ₹${_amount(bill.total)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_PersonAction>(
                    tooltip: 'Person options',
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    onSelected: (action) {
                      if (action == _PersonAction.delete) onDelete();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _PersonAction.delete,
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.error,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: colors.$2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 19),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'View',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 22),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _amount(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }
}

enum _PersonAction { delete }

class _AddPersonCard extends StatelessWidget {
  const _AddPersonCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, size: 30),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Add Person',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCDD2D9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 7), paint);
        distance += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
