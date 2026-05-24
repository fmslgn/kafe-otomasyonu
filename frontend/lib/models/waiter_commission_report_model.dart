// Yönetici garson prim raporu satır modelidir.
class WaiterCommissionReportModel {
  final int userId;
  final String fullName;
  final String username;
  final int closedOrderCount;
  final double totalSales;
  final double defaultRate;
  final double baseCommission;
  final double productBonus;
  final double visibleTotalCommission;
  final bool isEmployeeOfMonth;
  final double employeeOfMonthBonus;
  final double managerTotalCommission;

  const WaiterCommissionReportModel({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.closedOrderCount,
    required this.totalSales,
    required this.defaultRate,
    required this.baseCommission,
    required this.productBonus,
    required this.visibleTotalCommission,
    required this.isEmployeeOfMonth,
    required this.employeeOfMonthBonus,
    required this.managerTotalCommission,
  });

  factory WaiterCommissionReportModel.fromJson(Map<String, dynamic> json) {
    return WaiterCommissionReportModel(
      userId: json['user_id'] as int,
      fullName: json['full_name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      closedOrderCount: int.parse(json['closed_order_count'].toString()),
      totalSales: double.parse(json['total_sales'].toString()),
      defaultRate: double.parse(json['default_rate'].toString()),
      baseCommission: double.parse(json['base_commission'].toString()),
      productBonus: double.parse(json['product_bonus'].toString()),
      visibleTotalCommission:
          double.parse(json['visible_total_commission'].toString()),
      isEmployeeOfMonth: json['is_employee_of_month'] == true,
      employeeOfMonthBonus:
          double.parse(json['employee_of_month_bonus'].toString()),
      managerTotalCommission:
          double.parse(json['manager_total_commission'].toString()),
    );
  }
}

// Yönetici prim raporu API cevabı.
class WaiterCommissionReportResponse {
  final bool isEnabled;
  final String period;
  final List<WaiterCommissionReportModel> waiters;

  const WaiterCommissionReportResponse({
    required this.isEnabled,
    required this.period,
    required this.waiters,
  });

  factory WaiterCommissionReportResponse.fromJson(Map<String, dynamic> json) {
    final liste = (json['waiters'] as List<dynamic>? ?? [])
        .map((e) => WaiterCommissionReportModel.fromJson(e))
        .toList();

    return WaiterCommissionReportResponse(
      isEnabled: json['is_enabled'] == true,
      period: json['period']?.toString() ?? 'monthly',
      waiters: liste,
    );
  }

  WaiterCommissionReportModel? get ayinElemani {
    for (final garson in waiters) {
      if (garson.isEmployeeOfMonth) {
        return garson;
      }
    }
    return null;
  }
}
