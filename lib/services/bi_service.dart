import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bi_models.dart';

class BiSnapshot {
  final DashboardStats stats;
  final List<WeightPoint> weightSeries;
  final List<LotMetric> lots;
  final List<CategoryMetric> categories;

  const BiSnapshot({
    required this.stats,
    required this.weightSeries,
    required this.lots,
    required this.categories,
  });
}

class BiService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<BiSnapshot> load(String farmId) async {
    final results = await Future.wait([
      _client.rpc('farm_dashboard_stats', params: {'p_farm_id': farmId}),
      _client.rpc('farm_weight_series', params: {'p_farm_id': farmId, 'p_months': 12}),
      _client.rpc('farm_lot_distribution', params: {'p_farm_id': farmId}),
      _client.rpc('farm_category_distribution', params: {'p_farm_id': farmId}),
    ]);

    return BiSnapshot(
      stats: DashboardStats.fromMap(Map<String, dynamic>.from(results[0] as Map)),
      weightSeries: (results[1] as List)
          .map((e) => WeightPoint.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      lots: (results[2] as List)
          .map((e) => LotMetric.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      categories: (results[3] as List)
          .map((e) => CategoryMetric.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
