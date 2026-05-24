// En çok satılan ürün modelidir.
// Raporlama ekranında ürün satış performansını göstermek için kullanılır.
class TopProductModel {
  final int productId;
  final String productName;
  final String categoryName;
  final int totalQuantity;
  final double totalRevenue;

  const TopProductModel({
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.totalQuantity,
    required this.totalRevenue,
  });

  factory TopProductModel.fromJson(Map<String, dynamic> json) {
    return TopProductModel(
      productId: int.parse(json['product_id'].toString()),
      productName: json['product_name'].toString(),
      categoryName: json['category_name'].toString(),
      totalQuantity: int.parse(json['total_quantity'].toString()),
      totalRevenue: double.parse(json['total_revenue'].toString()),
    );
  }
}