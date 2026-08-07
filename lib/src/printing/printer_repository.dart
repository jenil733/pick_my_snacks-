import 'dart:convert';

import 'package:pick_my_snacks/src/core/services/local_storage.dart';
import 'package:pick_my_snacks/src/printing/printer_settings_model.dart';

abstract class PrinterRepository {
  PrinterSettingsModel? getPrinter(PrinterRole role);

  Future<void> savePrinter(PrinterRole role, PrinterSettingsModel printer);

  Future<void> removePrinter(PrinterRole role);
}

class LocalPrinterRepository implements PrinterRepository {
  LocalPrinterRepository(this._storage);

  static const _keyPrefix = 'configured_printer_';

  final LocalStorageService _storage;

  String _key(PrinterRole role) => '$_keyPrefix${role.name}';

  @override
  PrinterSettingsModel? getPrinter(PrinterRole role) {
    final value = _storage.getString(_key(role));
    if (value == null || value.trim().isEmpty) return null;

    try {
      final json = jsonDecode(value);
      if (json is! Map) return null;
      final printer = PrinterSettingsModel.fromJson(
        Map<String, dynamic>.from(json),
      );
      return printer.address.trim().isEmpty ? null : printer;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePrinter(
    PrinterRole role,
    PrinterSettingsModel printer,
  ) async {
    await _storage.setString(_key(role), jsonEncode(printer.toJson()));
  }

  @override
  Future<void> removePrinter(PrinterRole role) async {
    await _storage.remove(_key(role));
  }
}
