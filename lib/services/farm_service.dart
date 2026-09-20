import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/farm.dart';

class FarmService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Farm>> listFarms() async {
    final rows = await _client
        .from('farm_members')
        .select('role, farms(id,name,city,state)')
        .order('created_at');
    return (rows as List)
        .map((row) => Farm.fromMembership(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<Farm> createFarm({
    required String name,
    String? city,
    String? state,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Usuário não autenticado.');

    final farmName = name.trim();
    await _client.from('farms').insert({
      'owner_id': user.id,
      'name': farmName,
      'city': city?.trim(),
      'state': state?.trim().toUpperCase(),
    });

    final farms = await listFarms();
    final created = farms.where((farm) => farm.name == farmName).toList();
    if (created.isEmpty) {
      throw Exception('Fazenda criada, mas não foi possível carregar o acesso.');
    }
    return created.last;
  }

  Future<List<Map<String, dynamic>>> members(String farmId) async {
    final rows = await _client
        .from('farm_members')
        .select('role, created_at, profiles(id,full_name,email)')
        .eq('farm_id', farmId)
        .order('created_at');
    return (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> invite({
    required String farmId,
    required String email,
    required String role,
    String mode = 'invite',
    String fullName = '',
    String password = '',
  }) async {
    final response = await _client.functions.invoke(
      'invite-farm-member',
      body: {
        'farm_id': farmId,
        'email': email.trim(),
        'role': role,
        'mode': mode,
        'full_name': fullName.trim(),
        'password': password,
      },
    );
    if (response.status < 200 || response.status >= 300) {
      final data = response.data;
      throw Exception(data is Map ? data['error'] ?? 'Falha ao convidar.' : 'Falha ao convidar.');
    }
  }

  Future<void> removeMember(String farmId, String userId) async {
    await _client
        .from('farm_members')
        .delete()
        .eq('farm_id', farmId)
        .eq('user_id', userId);
  }
}
