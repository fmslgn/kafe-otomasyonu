// Malzeme alım modelidir.
// material_purchases tablosundan gelen kayıtları Flutter içinde kullanmak için oluşturuldu.
class MaterialPurchaseModel {
  final int id;
  final String itemName;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double totalPrice;
  final String? description;
  final String purchaseDate;
  final String createdAt;

  const MaterialPurchaseModel({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
    this.description,
    required this.purchaseDate,
    required this.createdAt,
  });

  factory MaterialPurchaseModel.fromJson(Map<String, dynamic> json) {
    return MaterialPurchaseModel(
      id: json['id'] as int,
      itemName: json['item_name']?.toString() ?? '',
      quantity: double.parse(json['quantity'].toString()),
      unit: json['unit']?.toString() ?? 'adet',
      unitPrice: double.parse(json['unit_price'].toString()),
      totalPrice: double.parse(json['total_price'].toString()),
      description: json['description']?.toString(),
      purchaseDate: json['purchase_date'].toString(),
      createdAt: json['created_at'].toString(),
    );
  }

  // Miktar ve birim bilgisini birleştirir (örn. 10 litre).
  String miktarBirimMetni() {
    final miktarStr = quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(2);
    return '$miktarStr $unit';
  }

  // Tarihi gün.ay.yıl formatında döndürür.
  String tarihGosterimi() {
    try {
      final dateTime = DateTime.parse(purchaseDate).toLocal();
      final gun = dateTime.day.toString().padLeft(2, '0');
      final ay = dateTime.month.toString().padLeft(2, '0');
      return '$gun.$ay.${dateTime.year}';
    } catch (_) {
      return purchaseDate;
    }
  }
}
