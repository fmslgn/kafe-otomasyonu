// Gelir-gider özet modelidir.
// Backend'den gelen toplam gelir, toplam gider ve net kazanç bilgilerini tutar.
class FinanceSummaryModel {
  // Kapanmış siparişlerden gelen toplam gelir.
  final double totalIncome;

  // Gider tablosundaki toplam gider.
  final double totalExpense;

  // Net kazanç: gelir - gider.
  final double netProfit;

  // Diğer (expenses) gider toplamı.
  final double normalExpense;

  // Malzeme alım gider toplamı.
  final double materialExpense;

  const FinanceSummaryModel({
    required this.totalIncome,
    required this.totalExpense,
    required this.netProfit,
    required this.normalExpense,
    required this.materialExpense,
  });

  factory FinanceSummaryModel.fromJson(Map<String, dynamic> json) {
    final toplamGider = double.parse(json['totalExpense'].toString());
    final digerGider = json['normalExpense'] != null
        ? double.parse(json['normalExpense'].toString())
        : toplamGider;
    final malzemeGider = json['materialExpense'] != null
        ? double.parse(json['materialExpense'].toString())
        : 0.0;

    return FinanceSummaryModel(
      totalIncome: double.parse(json['totalIncome'].toString()),
      totalExpense: toplamGider,
      netProfit: double.parse(json['netProfit'].toString()),
      normalExpense: digerGider,
      materialExpense: malzemeGider,
    );
  }
}