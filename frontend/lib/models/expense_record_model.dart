// Birleşik gider kaydı modelidir (normal gider + malzeme alımı).
class ExpenseRecordModel {
  final int id;
  final String type;
  final String title;
  final double amount;
  final String? description;
  final String recordDate;
  final String createdAt;
  final double? quantity;
  final String? unit;
  final double? unitPrice;

  const ExpenseRecordModel({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    this.description,
    required this.recordDate,
    required this.createdAt,
    this.quantity,
    this.unit,
    this.unitPrice,
  });

  bool get malzemeKaydi => type == 'material';

  factory ExpenseRecordModel.fromJson(Map<String, dynamic> json) {
    return ExpenseRecordModel(
      id: json['id'] as int,
      type: json['type']?.toString() ?? 'normal',
      title: json['title']?.toString() ?? '',
      amount: double.parse(json['amount'].toString()),
      description: json['description']?.toString(),
      recordDate: json['record_date'].toString(),
      createdAt: json['created_at'].toString(),
      quantity: json['quantity'] != null
          ? double.parse(json['quantity'].toString())
          : null,
      unit: json['unit']?.toString(),
      unitPrice: json['unit_price'] != null
          ? double.parse(json['unit_price'].toString())
          : null,
    );
  }

  String etiketMetni() {
    return malzemeKaydi ? 'Malzeme Alımı' : 'Genel Gider';
  }

  String tarihGosterimi() {
    try {
      final dateTime = DateTime.parse(recordDate).toLocal();
      final gun = dateTime.day.toString().padLeft(2, '0');
      final ay = dateTime.month.toString().padLeft(2, '0');
      return '$gun.$ay.${dateTime.year}';
    } catch (_) {
      return recordDate;
    }
  }

  String? miktarBirimMetni() {
    if (quantity == null || unit == null || unit!.isEmpty) {
      return null;
    }
    final miktarStr = quantity == quantity!.roundToDouble()
        ? quantity!.toInt().toString()
        : quantity!.toStringAsFixed(2);
    return '$miktarStr $unit';
  }
}
