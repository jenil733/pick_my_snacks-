enum PrinterRole {
  billing('Billing Printer'),
  kitchen('Kitchen Printer'),
  takeAway('Take Away Printer'),
  bar('Bar Printer'),
  drinks('Drinks Printer'),
  parcel('Parcel Printer'),
  token('Token Printer');

  const PrinterRole(this.label);

  final String label;
}

enum PrinterConnectionType {
  bluetooth('Bluetooth'),
  wifi('Wi-Fi');

  const PrinterConnectionType(this.label);

  final String label;
}

class PrinterSettingsModel {
  const PrinterSettingsModel({
    required this.name,
    required this.address,
    required this.connectionType,
  });

  factory PrinterSettingsModel.fromJson(Map<String, dynamic> json) {
    return PrinterSettingsModel(
      name: json['name']?.toString() ?? 'Unnamed printer',
      address: json['address']?.toString() ?? '',
      connectionType: PrinterConnectionType.values.firstWhere(
        (type) => type.name == json['connectionType'],
        orElse: () => PrinterConnectionType.bluetooth,
      ),
    );
  }

  final String name;
  final String address;
  final PrinterConnectionType connectionType;

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'connectionType': connectionType.name,
  };
}
