import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../models/farm.dart';
import '../services/animal_service.dart';
import '../core/app_theme.dart';

class AnimalPicker {
  static Future<Animal?> show(BuildContext context, Farm farm) {
    return showModalBottomSheet<Animal>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AnimalPickerSheet(farm: farm),
    );
  }
}

class _AnimalPickerSheet extends StatefulWidget {
  final Farm farm;
  const _AnimalPickerSheet({required this.farm});

  @override
  State<_AnimalPickerSheet> createState() => _AnimalPickerSheetState();
}

class _AnimalPickerSheetState extends State<_AnimalPickerSheet> {
  final _search = TextEditingController();
  List<Animal> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await AnimalService().listAnimals(widget.farm.id, search: _search.text);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Selecionar animal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nome, brinco, lote ou raça',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _load(),
                  onChanged: (_) => _load(),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                        ? const Center(child: Text('Nenhum animal encontrado.'))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final animal = _items[index];
                              return Card(
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: AppColors.lightGreen,
                                    child: Icon(Icons.agriculture, color: AppColors.darkGreen),
                                  ),
                                  title: Text(animal.displayName, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  subtitle: Text('${animal.brinco} • ${animal.lote.isEmpty ? 'Sem lote' : animal.lote}'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => Navigator.pop(context, animal),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      );
}
