import '../core/formatters.dart';

class HealthEvent {
  final String id;
  final String animalId;
  final String eventType;
  final String product;
  final DateTime eventDate;
  final DateTime? nextDueDate;
  final String notes;

  const HealthEvent({
    required this.id,
    required this.animalId,
    required this.eventType,
    required this.product,
    required this.eventDate,
    required this.notes,
    this.nextDueDate,
  });

  factory HealthEvent.fromMap(Map<String, dynamic> map) => HealthEvent(
        id: map['id'].toString(),
        animalId: map['animal_id'].toString(),
        eventType: (map['event_type'] ?? 'Outro').toString(),
        product: (map['product'] ?? '').toString(),
        eventDate: AppFormatters.parseDate(map['event_date']) ?? DateTime.now(),
        nextDueDate: AppFormatters.parseDate(map['next_due_date']),
        notes: (map['notes'] ?? '').toString(),
      );
}

class Weighing {
  final String id;
  final String animalId;
  final double weight;
  final DateTime measuredAt;
  final String notes;

  const Weighing({
    required this.id,
    required this.animalId,
    required this.weight,
    required this.measuredAt,
    required this.notes,
  });

  factory Weighing.fromMap(Map<String, dynamic> map) => Weighing(
        id: map['id'].toString(),
        animalId: map['animal_id'].toString(),
        weight: ((map['weight'] ?? 0) as num).toDouble(),
        measuredAt: AppFormatters.parseDate(map['measured_at']) ?? DateTime.now(),
        notes: (map['notes'] ?? '').toString(),
      );
}
