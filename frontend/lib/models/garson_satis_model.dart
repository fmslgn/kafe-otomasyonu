// Garson satış raporu modelidir.
// Yönetici, kullanıcı yönetimi ekranında garsonların yaptığı satışları görmek için kullanır.
class GarsonSatisModel {
  // Kullanıcının id değeridir.
  final int userId;

  // Kullanıcının ad soyad bilgisidir.
  final String fullName;

  // Kullanıcı adıdır.
  final String username;

  // Kullanıcı rolüdür.
  final String role;

  // Kapatılan hesap sayısıdır.
  final int closedOrderCount;

  // Toplam satış tutarıdır.
  final double totalSales;

  // Constructor yapısıdır.
  const GarsonSatisModel({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.role,
    required this.closedOrderCount,
    required this.totalSales,
  });

  // Backend API'den gelen JSON verisini GarsonSatisModel nesnesine dönüştürür.
  factory GarsonSatisModel.fromJson(Map<String, dynamic> json) {
    return GarsonSatisModel(
      userId: int.parse(json['user_id'].toString()),
      fullName: json['full_name'].toString(),
      username: json['username'].toString(),
      role: json['role'].toString(),
      closedOrderCount: int.parse(json['closed_order_count'].toString()),
      totalSales: double.parse(json['total_sales'].toString()),
    );
  }
}