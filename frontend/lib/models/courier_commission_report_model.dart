// Kurye prim raporu modelleri.

class CourierCommissionItemModel {
  final int userId;
  final String fullName;
  final String username;
  final int deliveredOrderCount;
  final double deliveredSales;
  final double courierDefaultRate;
  final double salesCommission;
  final double deliveryBonus;
  final double visibleTotalCommission;

  const CourierCommissionItemModel({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.deliveredOrderCount,
    required this.deliveredSales,
    required this.courierDefaultRate,
    required this.salesCommission,
    required this.deliveryBonus,
    required this.visibleTotalCommission,
  });

  factory CourierCommissionItemModel.fromJson(Map<String, dynamic> json) {
    return CourierCommissionItemModel(
      userId: int.parse(json['user_id'].toString()),
      fullName: json['full_name'].toString(),
      username: json['username'].toString(),
      deliveredOrderCount:
          int.parse(json['delivered_order_count'].toString()),
      deliveredSales: double.parse(json['delivered_sales'].toString()),
      courierDefaultRate:
          double.parse(json['courier_default_rate'].toString()),
      salesCommission: double.parse(json['sales_commission'].toString()),
      deliveryBonus: double.parse(json['delivery_bonus'].toString()),
      visibleTotalCommission:
          double.parse(json['visible_total_commission'].toString()),
    );
  }
}

class CourierCommissionReportResponse {
  final bool isEnabled;
  final String period;
  final List<CourierCommissionItemModel> couriers;

  const CourierCommissionReportResponse({
    required this.isEnabled,
    required this.period,
    required this.couriers,
  });

  factory CourierCommissionReportResponse.fromJson(Map<String, dynamic> json) {
    final liste = json['couriers'] as List<dynamic>? ?? [];
    return CourierCommissionReportResponse(
      isEnabled: json['is_enabled'] == true,
      period: json['period']?.toString() ?? 'monthly',
      couriers: liste
          .map((e) => CourierCommissionItemModel.fromJson(
                e as Map<String, dynamic>,
              ))
          .toList(),
    );
  }
}

class MyCourierCommissionReportModel {
  final bool isEnabled;
  final int userId;
  final String fullName;
  final int deliveredOrderCount;
  final double deliveredSales;
  final double courierDefaultRate;
  final double salesCommission;
  final double deliveryBonus;
  final double visibleTotalCommission;

  const MyCourierCommissionReportModel({
    required this.isEnabled,
    required this.userId,
    required this.fullName,
    required this.deliveredOrderCount,
    required this.deliveredSales,
    required this.courierDefaultRate,
    required this.salesCommission,
    required this.deliveryBonus,
    required this.visibleTotalCommission,
  });

  factory MyCourierCommissionReportModel.fromJson(Map<String, dynamic> json) {
    return MyCourierCommissionReportModel(
      isEnabled: json['is_enabled'] == true,
      userId: int.parse(json['user_id'].toString()),
      fullName: json['full_name'].toString(),
      deliveredOrderCount:
          int.parse(json['delivered_order_count'].toString()),
      deliveredSales: double.parse(json['delivered_sales'].toString()),
      courierDefaultRate:
          double.parse(json['courier_default_rate'].toString()),
      salesCommission: double.parse(json['sales_commission'].toString()),
      deliveryBonus: double.parse(json['delivery_bonus'].toString()),
      visibleTotalCommission:
          double.parse(json['visible_total_commission'].toString()),
    );
  }
}
