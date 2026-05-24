// Uygulama kullanıcı modelidir.
// Garson ve yönetici kullanıcılarını Flutter içinde temsil eder.
class AppUserModel {
  // Kullanıcının veritabanındaki id değeridir.
  final int id;

  // Kullanıcının ad soyad bilgisidir.
  final String fullName;

  // Kullanıcı giriş adıdır.
  final String username;

  // Kullanıcının rolüdür.
  // Örnek: garson, yonetici
  final String role;

  // Kullanıcının aktif/pasif durumudur.
  final bool isActive;

  // Kullanıcının oluşturulma tarihidir.
  final String createdAt;

  // Yönetici kullanıcı listesinde gösterilen şifre (plain text).
  final String? password;

  const AppUserModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.password,
  });

  // Backend'den gelen JSON verisini AppUserModel nesnesine çevirir.
  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      id: int.parse(json['id'].toString()),
      fullName: json['full_name'].toString(),
      username: json['username'].toString(),
      role: json['role'].toString(),
      isActive: json['is_active'] == true,
      createdAt: json['created_at'].toString(),
      password: json['password']?.toString(),
    );
  }
}