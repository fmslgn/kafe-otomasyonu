// Masa modelidir.
// Backend API'den gelen masa verilerini Flutter içinde kullanmak için oluşturuldu.
class MasaModel {
  // Masa id değeridir.
  final int id;

  // Masa numarasıdır.
  final int tableNo;

  // Masa durumudur.
  // Örnek: bos, dolu
  final String status;

  // Masanın ait olduğu bölümdür.
  // Örnek: Genel, Bahçe, Teras, Salon
  final String section;

  // Constructor yapısıdır.
  const MasaModel({
    required this.id,
    required this.tableNo,
    required this.status,
    required this.section,
  });

  // Backend API'den gelen JSON verisini MasaModel nesnesine dönüştürür.
  factory MasaModel.fromJson(Map<String, dynamic> json) {
    return MasaModel(
      id: int.parse(json['id'].toString()),
      tableNo: int.parse(json['table_no'].toString()),
      status: json['status'].toString(),
      section: json['section']?.toString() ?? 'Genel',
    );
  }
}