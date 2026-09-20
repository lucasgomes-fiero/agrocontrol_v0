import '../core/formatters.dart';

class AnimalMedia {
  final String id;
  final String animalId;
  final String farmId;
  final String mediaType;
  final String storagePath;
  final String caption;
  final DateTime takenAt;
  final String? healthEventId;

  const AnimalMedia({
    required this.id,
    required this.animalId,
    required this.farmId,
    required this.mediaType,
    required this.storagePath,
    required this.caption,
    required this.takenAt,
    this.healthEventId,
  });

  factory AnimalMedia.fromMap(Map<String, dynamic> map) => AnimalMedia(
        id: map['id'].toString(),
        animalId: map['animal_id'].toString(),
        farmId: map['farm_id'].toString(),
        mediaType: (map['media_type'] ?? 'Evolução').toString(),
        storagePath: (map['storage_path'] ?? '').toString(),
        caption: (map['caption'] ?? '').toString(),
        takenAt: AppFormatters.parseDate(map['taken_at']) ?? DateTime.now(),
        healthEventId: map['health_event_id']?.toString(),
      );
}
