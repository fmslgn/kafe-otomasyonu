// Ürün modelidir.

// Backend API'den gelen ürün verilerini Flutter içinde kullanmak için oluşturuldu.

class UrunModel {

  // Ürün id değeridir.

  final int id;



  // Ürün adıdır.

  final String name;



  // Ürün fiyatıdır.

  final double price;



  // Ürünün aktif olup olmadığını tutar.

  final bool isActive;



  // Ürünün kategori adıdır.

  final String categoryName;



  // Ürün açıklamasıdır.

  final String description;



  // Ürün görsel yolu (relative /uploads/... veya tam URL).

  final String? imageUrl;



  // Müşteri QR menüsünde görünüp görünmeyeceğini tutar.

  final bool isVisible;



  const UrunModel({

    required this.id,

    required this.name,

    required this.price,

    required this.isActive,

    required this.categoryName,

    this.description = '',

    this.imageUrl,

    this.isVisible = true,

  });



  factory UrunModel.fromJson(Map<String, dynamic> json) {

    final rawImageUrl = json['image_url'];



    return UrunModel(

      id: json['id'],

      name: json['name'],

      price: double.parse(json['price'].toString()),

      isActive: json['is_active'] == null ? true : json['is_active'] == true,

      categoryName: json['category_name'] ?? '',

      description: json['description']?.toString() ?? '',

      imageUrl: rawImageUrl == null ? null : rawImageUrl.toString(),

      isVisible: json['is_visible'] == null ? true : json['is_visible'] == true,

    );

  }



  @override

  bool operator ==(Object other) {

    return other is UrunModel && other.id == id;

  }



  @override

  int get hashCode => id.hashCode;

}

