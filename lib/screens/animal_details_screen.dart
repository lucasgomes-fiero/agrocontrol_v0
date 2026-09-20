import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/animal.dart';
import '../models/animal_media.dart';
import '../models/farm.dart';
import '../models/health_event.dart';
import '../services/animal_service.dart';
import '../widgets/async_animal_image.dart';
import '../widgets/status_badge.dart';
import 'animal_form_screen.dart';
import 'health_form_screen.dart';
import 'media_form_screen.dart';
import 'weighing_form_screen.dart';

class AnimalDetailsScreen extends StatefulWidget {
  final Farm farm;
  final Animal animal;

  const AnimalDetailsScreen({
    super.key,
    required this.farm,
    required this.animal,
  });

  @override
  State<AnimalDetailsScreen> createState() => _AnimalDetailsScreenState();
}

class _AnimalDetailsScreenState extends State<AnimalDetailsScreen> {
  late Animal _animal;
  List<AnimalMedia> _media = const [];
  List<HealthEvent> _health = const [];
  List<Weighing> _weighings = const [];
  bool _loading = true;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final values = await Future.wait([
        AnimalService().getAnimal(_animal.id),
        AnimalService().media(_animal.id),
        AnimalService().health(_animal.id),
        AnimalService().weighings(_animal.id),
      ]);
      if (!mounted) return;
      setState(() {
        _animal = values[0] as Animal;
        _media = values[1] as List<AnimalMedia>;
        _health = values[2] as List<HealthEvent>;
        _weighings = values[3] as List<Weighing>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao carregar histórico: $error')));
    }
  }

  Future<void> _push(Widget screen) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => screen));
    if (changed == true) {
      _changed = true;
      await _load();
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir animal?'),
        content: const Text('Pesagens, registros de saúde e linha do tempo também serão removidos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AnimalService().deleteAnimal(_animal.id);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível excluir: $error')));
    }
  }

  List<_TimelineItem> get _timeline {
    final items = <_TimelineItem>[
      ..._media.map((m) => _TimelineItem(
            date: m.takenAt,
            icon: Icons.photo_camera_outlined,
            color: AppColors.plantingGreen,
            title: m.mediaType,
            subtitle: m.caption.isEmpty ? 'Registro fotográfico' : m.caption,
            media: m,
          )),
      ..._health.map((h) => _TimelineItem(
            date: h.eventDate,
            icon: h.eventType == 'Vacina' ? Icons.vaccines_outlined : Icons.health_and_safety_outlined,
            color: AppColors.earth,
            title: h.eventType,
            subtitle: h.product.isEmpty ? h.notes : h.product,
          )),
      ..._weighings.map((w) => _TimelineItem(
            date: w.measuredAt,
            icon: Icons.monitor_weight_outlined,
            color: AppColors.sky,
            title: 'Pesagem',
            subtitle: AppFormatters.weight(w.weight),
          )),
    ];
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) Navigator.pop(context, _changed);
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(onPressed: () => Navigator.pop(context, _changed), icon: const Icon(Icons.arrow_back)),
            title: const Text('Animal'),
            actions: [
              IconButton(
                tooltip: 'Editar',
                onPressed: () => _push(AnimalFormScreen(farm: widget.farm, animal: _animal)),
                icon: const Icon(Icons.edit_outlined),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delete') _delete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'delete', child: Text('Excluir animal')),
                ],
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      Stack(
                        children: [
                          AsyncAnimalImage(
                            path: _animal.coverPath,
                            width: double.infinity,
                            height: 230,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          Positioned(
                            left: 14,
                            right: 14,
                            bottom: 14,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .93),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_animal.displayName, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                                        const SizedBox(height: 4),
                                        Text('${_animal.brinco} • ${_animal.raca.isEmpty ? _animal.especie : _animal.raca}'),
                                      ],
                                    ),
                                  ),
                                  StatusBadge(status: _animal.status),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              key: const Key('detailAddPhoto'),
                              onPressed: () => _push(MediaFormScreen(farm: widget.farm, animal: _animal)),
                              icon: const Icon(Icons.add_a_photo_outlined),
                              label: const Text('Foto'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('detailAddWeighing'),
                              onPressed: () => _push(WeighingFormScreen(farm: widget.farm, animal: _animal)),
                              icon: const Icon(Icons.monitor_weight_outlined),
                              label: const Text('Pesagem'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('detailAddHealth'),
                              onPressed: () => _push(HealthFormScreen(farm: widget.farm, animal: _animal)),
                              icon: const Icon(Icons.vaccines_outlined),
                              label: const Text('Saúde'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            runSpacing: 14,
                            spacing: 14,
                            children: [
                              _Data(label: 'Peso atual', value: AppFormatters.weight(_animal.pesoAtual)),
                              _Data(label: 'Sexo', value: _animal.sexo),
                              _Data(label: 'Categoria', value: _animal.categoria),
                              _Data(label: 'Nascimento', value: AppFormatters.date(_animal.dataNascimento)),
                              _Data(label: 'Lote', value: _animal.lote.isEmpty ? '—' : _animal.lote),
                              _Data(label: 'Origem', value: _animal.origem.isEmpty ? '—' : _animal.origem),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(child: Text('Linha do tempo', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
                          Text('${_timeline.length} registros', style: const TextStyle(color: AppColors.muted)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_timeline.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'Adicione fotos, pesagens, vacinas e registros de manejo para construir a história do animal.',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                        )
                      else
                        ...List.generate(_timeline.length, (index) {
                          final item = _timeline[index];
                          return _TimelineTile(item: item, last: index == _timeline.length - 1);
                        }),
                    ],
                  ),
                ),
        ),
      );
}

class _Data extends StatelessWidget {
  final String label;
  final String value;
  const _Data({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 145,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class _TimelineItem {
  final DateTime date;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final AnimalMedia? media;

  const _TimelineItem({
    required this.date,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.media,
  });
}

class _TimelineTile extends StatelessWidget {
  final _TimelineItem item;
  final bool last;
  const _TimelineTile({required this.item, required this.last});

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 46,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: item.color.withValues(alpha: .12),
                    child: Icon(item.icon, color: item.color, size: 19),
                  ),
                  if (!last)
                    Expanded(
                      child: Container(width: 2, color: item.color.withValues(alpha: .20)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.media != null) ...[
                          AsyncAnimalImage(path: item.media!.storagePath, width: 74, height: 74, borderRadius: BorderRadius.circular(12)),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              if (item.subtitle.isNotEmpty)
                                Text(item.subtitle, style: const TextStyle(color: AppColors.muted)),
                              const SizedBox(height: 7),
                              Text(AppFormatters.date(item.date), style: TextStyle(color: item.color, fontSize: 12, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
