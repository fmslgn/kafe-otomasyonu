// Paket sipariş modelidir.
// Dışarıdan alınan paket siparişlerin liste ekranında,
// kurye atama ekranında ve kurye panelinde gösterilmesi için kullanılır.
class PaketSiparisModel {
  // Paket sipariş id değeridir.
  final int id;

  // Müşteri adıdır.
  final String? customerName;

  // Müşteri telefonudur.
  final String? customerPhone;

  // Teslimat adresidir.
  final String? address;

  // Paket sipariş notudur.
  final String? note;

  // Sipariş toplam tutarıdır.
  final double totalPrice;

  // Sipariş durumudur.
  // aktif, kapandi veya iptal olabilir.
  final String status;

  // Teslimat durumudur.
  // bekliyor, kuryeye_atandi, yolda, teslim_edildi, iptal olabilir.
  final String deliveryStatus;

  // Siparişi alan personel adıdır.
  final String? waiterName;

  // Siparişe atanmış kurye id değeridir.
  final int? courierId;

  // Siparişe atanmış kurye adıdır.
  final String? courierName;

  // Siparişteki toplam ürün adedidir.
  final int itemCount;

  // Sipariş oluşturulma tarihidir.
  final String createdAt;

  // Constructor yapısıdır.
  PaketSiparisModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.note,
    required this.totalPrice,
    required this.status,
    required this.deliveryStatus,
    required this.waiterName,
    required this.courierId,
    required this.courierName,
    required this.itemCount,
    required this.createdAt,
  });

  // JSON alanını güvenli metne çevirir; boşsa null döner.
  static String? _opsiyonelMetin(dynamic deger) {
    if (deger == null) return null;
    final metin = deger.toString().trim();
    return metin.isEmpty ? null : metin;
  }

  // JSON alanını güvenli sayıya çevirir.
  static double _guvenliDouble(dynamic deger) {
    if (deger == null) return 0;
    if (deger is num) return deger.toDouble();
    return double.tryParse(deger.toString()) ?? 0;
  }

  static int _guvenliInt(dynamic deger) {
    if (deger == null) return 0;
    if (deger is int) return deger;
    if (deger is num) return deger.toInt();
    return int.tryParse(deger.toString()) ?? 0;
  }

  // snake_case veya camelCase anahtarlardan alan okur.
  static dynamic _oku(Map<String, dynamic> json, String snake, String camel) {
    return json[snake] ?? json[camel];
  }

  // JSON verisini PaketSiparisModel nesnesine çevirir (null güvenli).
  factory PaketSiparisModel.fromJson(Map<String, dynamic> json) {
    return PaketSiparisModel(
      id: _guvenliInt(_oku(json, 'id', 'id')),
      customerName: _opsiyonelMetin(
        _oku(json, 'customer_name', 'customerName'),
      ),
      customerPhone: _opsiyonelMetin(
        _oku(json, 'customer_phone', 'customerPhone'),
      ),
      address: _opsiyonelMetin(_oku(json, 'address', 'address')),
      note: _opsiyonelMetin(_oku(json, 'note', 'note')),
      totalPrice: _guvenliDouble(_oku(json, 'total_price', 'totalPrice')),
      status: _opsiyonelMetin(_oku(json, 'status', 'status')) ?? 'aktif',
      deliveryStatus: _opsiyonelMetin(
            _oku(json, 'delivery_status', 'deliveryStatus'),
          ) ??
          'bekliyor',
      waiterName: _opsiyonelMetin(_oku(json, 'waiter_name', 'waiterName')),
      courierId: () {
        final ham = _oku(json, 'courier_id', 'courierId');
        if (ham == null) return null;
        final parsed = int.tryParse(ham.toString());
        return parsed;
      }(),
      courierName: _opsiyonelMetin(_oku(json, 'courier_name', 'courierName')),
      itemCount: _guvenliInt(_oku(json, 'item_count', 'itemCount')),
      createdAt: _opsiyonelMetin(_oku(json, 'created_at', 'createdAt')) ?? '',
    );
  }
}