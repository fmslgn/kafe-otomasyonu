// Prim sistemi genel ayar modelidir (garson + kurye).
class CommissionSettingsModel {
  final int id;
  final bool isEnabled;
  final double defaultRate;
  final double employeeOfMonthBonus;
  final bool courierCommissionEnabled;
  final double courierDefaultRate;
  final double courierDeliveryBonus;

  const CommissionSettingsModel({
    required this.id,
    required this.isEnabled,
    required this.defaultRate,
    required this.employeeOfMonthBonus,
    required this.courierCommissionEnabled,
    required this.courierDefaultRate,
    required this.courierDeliveryBonus,
  });

  factory CommissionSettingsModel.fromJson(Map<String, dynamic> json) {
    return CommissionSettingsModel(
      id: int.parse(json['id'].toString()),
      isEnabled: json['is_enabled'] == true,
      defaultRate: double.parse(json['default_rate'].toString()),
      employeeOfMonthBonus:
          double.parse(json['employee_of_month_bonus'].toString()),
      courierCommissionEnabled: json['courier_commission_enabled'] == true,
      courierDefaultRate:
          double.parse(json['courier_default_rate']?.toString() ?? '3'),
      courierDeliveryBonus:
          double.parse(json['courier_delivery_bonus']?.toString() ?? '0'),
    );
  }
}
