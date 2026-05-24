// Rapor özet modelidir.
// Backend'den gelen genel satış, masa satış ve paket satış bilgilerini tutar.
class ReportSummaryModel {
  // Seçili dönem bilgisidir.
  // all, daily, weekly, monthly olabilir.
  final String period;

  // Masa + paket toplam satış tutarıdır.
  final double totalSales;

  // Kapanan masa siparişi + kapanan paket siparişi sayısıdır.
  final int closedOrderCount;

  // Ortalama sipariş tutarıdır.
  final double averageOrderAmount;

  // Masa + paket toplam satılan ürün adedidir.
  final int totalItemsSold;

  // Sadece masa siparişlerinden gelen toplam satış tutarıdır.
  final double tableSales;

  // Sadece paket siparişlerden gelen toplam satış tutarıdır.
  final double packageSales;

  // Kapanan masa siparişi sayısıdır.
  final int tableOrderCount;

  // Kapanan paket siparişi sayısıdır.
  final int packageOrderCount;

  // Constructor yapısıdır.
  ReportSummaryModel({
    required this.period,
    required this.totalSales,
    required this.closedOrderCount,
    required this.averageOrderAmount,
    required this.totalItemsSold,
    required this.tableSales,
    required this.packageSales,
    required this.tableOrderCount,
    required this.packageOrderCount,
  });

  // JSON verisini ReportSummaryModel nesnesine çevirir.
  factory ReportSummaryModel.fromJson(Map<String, dynamic> json) {
    return ReportSummaryModel(
      period: json['period']?.toString() ?? 'all',
      totalSales: double.tryParse(json['totalSales'].toString()) ?? 0,
      closedOrderCount:
          int.tryParse(json['closedOrderCount'].toString()) ?? 0,
      averageOrderAmount:
          double.tryParse(json['averageOrderAmount'].toString()) ?? 0,
      totalItemsSold: int.tryParse(json['totalItemsSold'].toString()) ?? 0,

      // Yeni backend alanlarıdır.
      // Eski veri gelirse 0 kabul edilir.
      tableSales: double.tryParse(json['tableSales'].toString()) ?? 0,
      packageSales: double.tryParse(json['packageSales'].toString()) ?? 0,
      tableOrderCount:
          int.tryParse(json['tableOrderCount'].toString()) ?? 0,
      packageOrderCount:
          int.tryParse(json['packageOrderCount'].toString()) ?? 0,
    );
  }
}