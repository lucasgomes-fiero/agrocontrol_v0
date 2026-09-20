import 'package:agrocontrol/models/animal.dart';
import 'package:agrocontrol/models/bi_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('animal parses Supabase payload', () {
    final animal = Animal.fromMap({
      'id': 'animal-1',
      'farm_id': 'farm-1',
      'brinco': 'AC-001',
      'nome': 'Nelore 01',
      'especie': 'Bovino',
      'raca': 'Nelore',
      'sexo': 'Macho',
      'categoria': 'Novilho',
      'data_nascimento': '2025-01-10',
      'lote': 'Pasto A',
      'origem': 'Fazenda',
      'peso_atual': 420.5,
      'status': 'Ativo',
      'observacao': '',
    });

    expect(animal.displayName, 'Nelore 01');
    expect(animal.pesoAtual, 420.5);
    expect(animal.farmId, 'farm-1');
  });

  test('dashboard stats parses RPC payload', () {
    final stats = DashboardStats.fromMap({
      'animals': 152,
      'active': 147,
      'treatment': 5,
      'avg_weight': 431.2,
      'weighings_month': 28,
      'health_month': 9,
      'vaccines_due': 4,
    });
    expect(stats.animals, 152);
    expect(stats.treatment, 5);
    expect(stats.avgWeight, 431.2);
  });
}
