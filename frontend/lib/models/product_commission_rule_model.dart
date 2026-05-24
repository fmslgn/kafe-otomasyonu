// Ürün bazlı ekstra prim kuralı modelidir.
class ProductCommissionRuleModel {
  final int id;
  final int productId;
  final String productName;
  final String categoryName;
  final double targetQuantity;
  final double bonusAmount;
  final bool isActive;

  const ProductCommissionRuleModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.targetQuantity,
    required this.bonusAmount,
    required this.isActive,
  });

  factory ProductCommissionRuleModel.fromJson(Map<String, dynamic> json) {
    return ProductCommissionRuleModel(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
      targetQuantity: double.parse(json['target_quantity'].toString()),
      bonusAmount: double.parse(json['bonus_amount'].toString()),
      isActive: json['is_active'] == true,
    );
  }
}
