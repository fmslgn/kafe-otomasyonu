// Kategori modelidir.
// Backend API'den gelen kategori verilerini Flutter içinde kullanmak için oluşturuldu.
class KategoriModel {
  // Kategori id değeridir.
  final int id;

  // Kategori adıdır.
  final String name;

  // Constructor yapısıdır.
  const KategoriModel({
    required this.id,
    required this.name,
  });

  // Backend API'den gelen JSON verisini KategoriModel nesnesine çevirir.
  factory KategoriModel.fromJson(Map<String, dynamic> json) {
    return KategoriModel(
      id: json['id'],
      name: json['name'],
    );
  }
}