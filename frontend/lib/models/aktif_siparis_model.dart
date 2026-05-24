// Aktif sipariş modelidir.
// Hesap işlemleri ekranında açık hesapları göstermek için kullanılır.
class AktifSiparisModel {
  // Sipariş id değeridir.
  final int id;

  // Siparişin ait olduğu masa numarasıdır.
  final int tableNo;

  // Sipariş toplam tutarıdır.
  final double totalPrice;

  // Sipariş durumudur.
  // Örnek: aktif, kapandi, iptal
  final String status;

  // Sipariş içindeki toplam ürün adedidir.
  final int itemCount;

  // Siparişin oluşturulma tarihidir.
  final String createdAt;

  // Constructor yapısıdır.
  const AktifSiparisModel({
    required this.id,
    required this.tableNo,
    required this.totalPrice,
    required this.status,
    required this.itemCount,
    required this.createdAt,
  });

  // Backend API'den gelen JSON verisini AktifSiparisModel nesnesine çevirir.
  factory AktifSiparisModel.fromJson(Map<String, dynamic> json) {
    return AktifSiparisModel(
      // Sipariş id değerini alır.
      id: json['id'],

      // Masa numarasını alır.
      tableNo: json['table_no'],

      // Toplam tutarı double türüne çevirir.
      totalPrice: double.parse(json['total_price'].toString()),

      // Sipariş durumunu alır.
      status: json['status'],

      // Siparişteki toplam ürün adedini alır.
      itemCount: json['item_count'],

      // Oluşturulma tarihini string olarak alır.
      createdAt: json['created_at'].toString(),
    );
  }
}