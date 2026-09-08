class CategoryResponse {
  const CategoryResponse({
    required this.success,
    required this.data,
    this.message,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    if (json['success'] != false && raw is! List) {
      throw const FormatException('Invalid categories response');
    }
    return CategoryResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (item) =>
                      BillingCategory.fromJson(Map<String, dynamic>.from(item)),
                )
                .where((item) => item.name.isNotEmpty)
                .toList()
          : [],
    );
  }

  final bool success;
  final List<BillingCategory> data;
  final String? message;
}

class BillingCategory {
  const BillingCategory({required this.id, required this.name, this.image});

  factory BillingCategory.fromJson(Map<String, dynamic> json) =>
      BillingCategory(
        id: int.parse(json['id'].toString()),
        name: (json['category'] ?? '').toString().trim(),
        image: json['image']?.toString(),
      );

  final int id;
  final String name;
  final String? image;
}
