// Kafe genel ayarları modelidir.
class CafeSettingsModel {
  final int id;
  final String cafeName;
  final String? openingHours;
  final String? address;
  final String? phone;
  final String? mapUrl;
  final String? instagramUrl;
  final bool isOpen;
  final String themeKey;
  final String primaryColor;
  final String menuLayout;
  final String? logoUrl;
  final String? updatedAt;

  const CafeSettingsModel({
    required this.id,
    required this.cafeName,
    this.openingHours,
    this.address,
    this.phone,
    this.mapUrl,
    this.instagramUrl,
    required this.isOpen,
    this.themeKey = 'brown',
    this.primaryColor = '#795548',
    this.menuLayout = 'vertical',
    this.logoUrl,
    this.updatedAt,
  });

  factory CafeSettingsModel.fromJson(Map<String, dynamic> json) {
    return CafeSettingsModel(
      id: int.parse(json['id'].toString()),
      cafeName: json['cafe_name']?.toString() ?? 'Kafe',
      openingHours: json['opening_hours']?.toString(),
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      mapUrl: json['map_url']?.toString(),
      instagramUrl: json['instagram_url']?.toString(),
      isOpen: json['is_open'] == true,
      themeKey: json['theme_key']?.toString().trim().isNotEmpty == true
          ? json['theme_key'].toString()
          : 'brown',
      primaryColor: json['primary_color']?.toString().trim().isNotEmpty == true
          ? json['primary_color'].toString()
          : '#795548',
      menuLayout: json['menu_layout']?.toString().trim().isNotEmpty == true
          ? json['menu_layout'].toString()
          : 'vertical',
      logoUrl: json['logo_url']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}
