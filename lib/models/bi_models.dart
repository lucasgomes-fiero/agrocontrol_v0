import '../core/formatters.dart';

class DashboardStats {
  final int animals;
  final int active;
  final int treatment;
  final double avgWeight;
  final int weighingsMonth;
  final int healthMonth;
  final int vaccinesDue;

  const DashboardStats({
    this.animals = 0,
    this.active = 0,
    this.treatment = 0,
    this.avgWeight = 0,
    this.weighingsMonth = 0,
    this.healthMonth = 0,
    this.vaccinesDue = 0,
  });

  factory DashboardStats.fromMap(Map<String, dynamic> map) => DashboardStats(
        animals: ((map['animals'] ?? 0) as num).toInt(),
        active: ((map['active'] ?? 0) as num).toInt(),
        treatment: ((map['treatment'] ?? 0) as num).toInt(),
        avgWeight: ((map['avg_weight'] ?? 0) as num).toDouble(),
        weighingsMonth: ((map['weighings_month'] ?? 0) as num).toInt(),
        healthMonth: ((map['health_month'] ?? 0) as num).toInt(),
        vaccinesDue: ((map['vaccines_due'] ?? 0) as num).toInt(),
      );
}

class WeightPoint {
  final DateTime month;
  final double average;
  final int records;
  const WeightPoint(this.month, this.average, this.records);

  factory WeightPoint.fromMap(Map<String, dynamic> map) => WeightPoint(
        AppFormatters.parseDate(map['month']) ?? DateTime.now(),
        ((map['avg_weight'] ?? 0) as num).toDouble(),
        ((map['total_records'] ?? 0) as num).toInt(),
      );
}

class LotMetric {
  final String name;
  final int total;
  final double averageWeight;
  const LotMetric(this.name, this.total, this.averageWeight);

  factory LotMetric.fromMap(Map<String, dynamic> map) => LotMetric(
        (map['lote'] ?? 'Sem lote').toString(),
        ((map['total'] ?? 0) as num).toInt(),
        ((map['avg_weight'] ?? 0) as num?)?.toDouble() ?? 0,
      );
}

class CategoryMetric {
  final String name;
  final int total;
  const CategoryMetric(this.name, this.total);

  factory CategoryMetric.fromMap(Map<String, dynamic> map) => CategoryMetric(
        (map['categoria'] ?? 'Não informado').toString(),
        ((map['total'] ?? 0) as num).toInt(),
      );
}
