import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_config.dart';
import '../core/formatters.dart';
import '../models/animal.dart';
import '../models/animal_media.dart';
import '../models/health_event.dart';

class AnimalService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Animal>> listAnimals(
    String farmId, {
    String search = '',
    String? status,
  }) async {
    var query = _client.from('animals').select().eq('farm_id', farmId);
    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }
    final rows = await query.order('created_at', ascending: false);
    final all = (rows as List)
        .map((row) => Animal.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
    final term = search.trim().toLowerCase();
    if (term.isEmpty) return all;
    return all.where((a) {
      return a.brinco.toLowerCase().contains(term) ||
          a.nome.toLowerCase().contains(term) ||
          a.lote.toLowerCase().contains(term) ||
          a.raca.toLowerCase().contains(term);
    }).toList();
  }

  Future<Animal> getAnimal(String id) async {
    final row = await _client.from('animals').select().eq('id', id).single();
    return Animal.fromMap(Map<String, dynamic>.from(row));
  }

  Future<Animal> saveAnimal({
    String? id,
    required String farmId,
    required String brinco,
    required String nome,
    required String especie,
    required String raca,
    required String sexo,
    required String categoria,
    DateTime? dataNascimento,
    required String lote,
    required String origem,
    required String status,
    required String observacao,
  }) async {
    final payload = <String, dynamic>{
      'farm_id': farmId,
      'brinco': brinco.trim(),
      'nome': nome.trim(),
      'especie': especie,
      'raca': raca.trim(),
      'sexo': sexo,
      'categoria': categoria,
      'data_nascimento': dataNascimento == null ? null : AppFormatters.isoDate(dataNascimento),
      'lote': lote.trim(),
      'origem': origem.trim(),
      'status': status,
      'observacao': observacao.trim(),
      'created_by': _client.auth.currentUser?.id,
    };
    final row = id == null
        ? await _client.from('animals').insert(payload).select().single()
        : await _client.from('animals').update(payload).eq('id', id).select().single();
    return Animal.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> deleteAnimal(String id) async {
    await _client.from('animals').delete().eq('id', id);
  }

  Future<void> addWeighing({
    required String farmId,
    required String animalId,
    required double weight,
    required DateTime date,
    String notes = '',
  }) async {
    await _client.from('weighings').insert({
      'farm_id': farmId,
      'animal_id': animalId,
      'weight': weight,
      'measured_at': AppFormatters.isoDate(date),
      'notes': notes.trim(),
      'created_by': _client.auth.currentUser?.id,
    });
  }

  Future<String> addHealthEvent({
    required String farmId,
    required String animalId,
    required String type,
    required String product,
    required DateTime date,
    DateTime? nextDueDate,
    String notes = '',
  }) async {
    final row = await _client.from('health_events').insert({
      'farm_id': farmId,
      'animal_id': animalId,
      'event_type': type,
      'product': product.trim(),
      'event_date': AppFormatters.isoDate(date),
      'next_due_date': nextDueDate == null ? null : AppFormatters.isoDate(nextDueDate),
      'notes': notes.trim(),
      'created_by': _client.auth.currentUser?.id,
    }).select('id').single();
    if (type == 'Tratamento' || type == 'Medicamento') {
      await _client.from('animals').update({'status': 'Em tratamento'}).eq('id', animalId);
    }
    return row['id'].toString();
  }

  Future<List<Weighing>> weighings(String animalId) async {
    final rows = await _client
        .from('weighings')
        .select()
        .eq('animal_id', animalId)
        .order('measured_at', ascending: false);
    return (rows as List)
        .map((e) => Weighing.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<HealthEvent>> health(String animalId) async {
    final rows = await _client
        .from('health_events')
        .select()
        .eq('animal_id', animalId)
        .order('event_date', ascending: false);
    return (rows as List)
        .map((e) => HealthEvent.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<AnimalMedia>> media(String animalId) async {
    final rows = await _client
        .from('animal_media')
        .select()
        .eq('animal_id', animalId)
        .order('taken_at', ascending: false)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => AnimalMedia.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<String> uploadMedia({
    required String farmId,
    required String animalId,
    required Uint8List bytes,
    required String extension,
    required String mediaType,
    required DateTime takenAt,
    String caption = '',
    String? healthEventId,
    bool setAsCover = false,
  }) async {
    final cleanExt = extension.toLowerCase().replaceAll('.', '');
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.${cleanExt.isEmpty ? 'jpg' : cleanExt}';
    final path = '$farmId/$animalId/$fileName';
    final contentType = cleanExt == 'png'
        ? 'image/png'
        : cleanExt == 'webp'
            ? 'image/webp'
            : 'image/jpeg';
    await _client.storage.from(AppConfig.storageBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    try {
      await _client.from('animal_media').insert({
        'farm_id': farmId,
        'animal_id': animalId,
        'health_event_id': healthEventId,
        'media_type': mediaType,
        'storage_path': path,
        'caption': caption.trim(),
        'taken_at': AppFormatters.isoDate(takenAt),
        'created_by': _client.auth.currentUser?.id,
      });
      if (setAsCover) {
        await _client.from('animals').update({'cover_path': path}).eq('id', animalId);
      }
      return path;
    } catch (_) {
      await _client.storage.from(AppConfig.storageBucket).remove([path]);
      rethrow;
    }
  }

  Future<String> signedUrl(String path) async {
    return _client.storage.from(AppConfig.storageBucket).createSignedUrl(path, 3600);
  }
}
