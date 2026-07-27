import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';

class PaymentMethodDropdown extends StatelessWidget {
  const PaymentMethodDropdown({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => DropdownButtonFormField<String>(
        initialValue: controller.paymentMethod.value,
        decoration: InputDecoration(
          labelText: 'Payment method',
          prefixIcon: const Icon(Icons.payments_outlined),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
        items: HomeController.paymentMethods
            .map(
              (method) =>
                  DropdownMenuItem(value: method, child: Text(_label(method))),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) controller.paymentMethod.value = value;
        },
      ),
    );
  }

  String _label(String value) {
    return value[0].toUpperCase() + value.substring(1);
  }
}
