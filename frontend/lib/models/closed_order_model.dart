// Kapanan hesap modelidir.
// Raporlama ekranında kapatılmış siparişleri listelemek için kullanılır.
class ClosedOrderModel {
  final int id;
  final int tableNo;
  final double totalPrice;
  final String status;
  final String createdAt;
  final int itemCount;

  const ClosedOrderModel({
    required this.id,
    required this.tableNo,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.itemCount,
  });

  factory ClosedOrderModel.fromJson(Map<String, dynamic> json) {
    return ClosedOrderModel(
      id: int.parse(json['id'].toString()),
      tableNo: int.parse(json['table_no'].toString()),
      totalPrice: double.parse(json['total_price'].toString()),
      status: json['status'].toString(),
      createdAt: json['created_at'].toString(),
      itemCount: int.parse(json['item_count'].toString()),
    );
  }
}