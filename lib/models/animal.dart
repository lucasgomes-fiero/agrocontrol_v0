import '../core/formatters.dart';

class Animal {
  final String id;
  final String farmId;
  final String brinco;
  final String nome;
  final String especie;
  final String raca;
  final String sexo;
  final String categoria;
  final DateTime? dataNascimento;
  final String lote;
  final String origem;
  final double pesoAtual;
  final String status;
  final String observacao;
  final String? coverPath;

  const Animal({
    required this.id,
    required this.farmId,
    required this.brinco,
    required this.nome,
    required this.especie,
    required this.raca,
    required this.sexo,
    required this.categoria,
    required this.lote,
    required this.origem,
    required this.pesoAtual,
    required this.status,
    required this.observacao,
    this.dataNascimento,
    this.coverPath,
  });

  String get displayName => nome.trim().isEmpty ? brinco : nome;

  factory Animal.fromMap(Map<String, dynamic> map) => Animal(
        id: map['id'].toString(),
        farmId: map['farm_id'].toString(),
        brinco: (map['brinco'] ?? '').toString(),
        nome: (map['nome'] ?? '').toString(),
        especie: (map['especie'] ?? 'Bovino').toString(),
        raca: (map['raca'] ?? '').toString(),
        sexo: (map['sexo'] ?? 'Macho').toString(),
        categoria: (map['categoria'] ?? 'Adulto').toString(),
        dataNascimento: AppFormatters.parseDate(map['data_nascimento']),
        lote: (map['lote'] ?? '').toString(),
        origem: (map['origem'] ?? '').toString(),
        pesoAtual: ((map['peso_atual'] ?? 0) as num).toDouble(),
        status: (map['status'] ?? 'Ativo').toString(),
        observacao: (map['observacao'] ?? '').toString(),
        coverPath: map['cover_path']?.toString(),
      );
}
