import 'cafe_event_model.dart';
import 'cafe_settings_model.dart';

// QR menü için public kafe bilgisi ve aktif etkinlikler.
class PublicCafeInfoModel {
  final CafeSettingsModel settings;
  final List<CafeEventModel> events;

  const PublicCafeInfoModel({
    required this.settings,
    required this.events,
  });

  factory PublicCafeInfoModel.fromJson(Map<String, dynamic> json) {
    final etkinlikler = json['events'] as List<dynamic>? ?? [];
    return PublicCafeInfoModel(
      settings: CafeSettingsModel.fromJson(
        json['settings'] as Map<String, dynamic>,
      ),
      events: etkinlikler
          .map((e) => CafeEventModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
