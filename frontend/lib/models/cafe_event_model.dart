// Kafe etkinlik / duyuru modelidir.
class CafeEventModel {
  final int id;
  final String title;
  final String? description;
  final String? eventDate;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  const CafeEventModel({
    required this.id,
    required this.title,
    this.description,
    this.eventDate,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory CafeEventModel.fromJson(Map<String, dynamic> json) {
    return CafeEventModel(
      id: int.parse(json['id'].toString()),
      title: json['title'].toString(),
      description: json['description']?.toString(),
      eventDate: json['event_date']?.toString(),
      isActive: json['is_active'] == true,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}
