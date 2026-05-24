// Garsonun kendi prim raporu modelidir (ayın elemanı özel primi yok).
class ProductBonusDetailModel {
  final String productName;
  final double soldQuantity;
  final double targetQuantity;
  final double bonusAmount;
  final bool earned;

  const ProductBonusDetailModel({
    required this.productName,
    required this.soldQuantity,
    required this.targetQuantity,
    required this.bonusAmount,
    required this.earned,
  });

  factory ProductBonusDetailModel.fromJson(Map<String, dynamic> json) {
    return ProductBonusDetailModel(
      productName: json['product_name']?.toString() ?? '',
      soldQuantity: double.parse(json['sold_quantity'].toString()),
      targetQuantity: double.parse(json['target_quantity'].toString()),
      bonusAmount: double.parse(json['bonus_amount'].toString()),
      earned: json['earned'] == true,
    );
  }
}

class MyCommissionReportModel {
  final bool isEnabled;
  final int userId;
  final String fullName;
  final int closedOrderCount;
  final double totalSales;
  final double defaultRate;
  final double baseCommission;
  final double productBonus;
  final double visibleTotalCommission;
  final List<ProductBonusDetailModel> productBonusDetails;

  const MyCommissionReportModel({
    required this.isEnabled,
    required this.userId,
    required this.fullName,
    required this.closedOrderCount,
    required this.totalSales,
    required this.defaultRate,
    required this.baseCommission,
    required this.productBonus,
    required this.visibleTotalCommission,
    required this.productBonusDetails,
  });

  factory MyCommissionReportModel.fromJson(Map<String, dynamic> json) {
    final detaylar = (json['product_bonus_details'] as List<dynamic>? ?? [])
        .map((e) => ProductBonusDetailModel.fromJson(e))
        .toList();

    return MyCommissionReportModel(
      isEnabled: json['is_enabled'] == true,
      userId: json['user_id'] as int,
      fullName: json['full_name']?.toString() ?? '',
      closedOrderCount: int.parse(json['closed_order_count'].toString()),
      totalSales: double.parse(json['total_sales'].toString()),
      defaultRate: double.parse(json['default_rate'].toString()),
      baseCommission: double.parse(json['base_commission'].toString()),
      productBonus: double.parse(json['product_bonus'].toString()),
      visibleTotalCommission:
          double.parse(json['visible_total_commission'].toString()),
      productBonusDetails: detaylar,
    );
  }
}
