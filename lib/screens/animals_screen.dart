import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/animal.dart';
import '../models/farm.dart';
import '../services/animal_service.dart';
import '../widgets/async_animal_image.dart';
import '../widgets/brand.dart';
import '../widgets/status_badge.dart';
import 'animal_details_screen.dart';
import 'animal_form_screen.dart';

class AnimalsScreen extends StatefulWidget {
  final Farm farm;
  final VoidCallback onChanged;

  const AnimalsScreen({
    super.key,
    required this.farm,
    required this.onChanged,
  });

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<Animal> _items = const [];
  bool _loading = true;
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await AnimalService().listAnimals(
        widget.farm.id,
        search: _search.text,
        status: _status,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao carregar animais: $error')));
    }
  }

  Future<void> _add() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AnimalFormScreen(farm: widget.farm)),
    );
    if (changed == true) {
      widget.onChanged();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('animalsAddButton'),
            onPressed: _add,
            backgroundColor: AppColors.darkGreen,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Cadastrar'),
          ),
          body: RefreshIndicator(
            onRefresh: _load,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AgroWordmark(height: 46),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Expanded(child: Text('Animais', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900))),
                            Text('${_items.length}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: const Key('animalSearchField'),
                          controller: _search,
                          decoration: const InputDecoration(
                            hintText: 'Buscar por brinco, nome, lote ou raça',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (_) {
                            _debounce?.cancel();
                            _debounce = Timer(const Duration(milliseconds: 250), _load);
                          },
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _Filter(label: 'Todos', selected: _status == null, onTap: () {
                                setState(() => _status = null);
                                _load();
                              }),
                              _Filter(label: 'Ativos', selected: _status == 'Ativo', onTap: () {
                                setState(() => _status = 'Ativo');
                                _load();
                              }),
                              _Filter(label: 'Em tratamento', selected: _status == 'Em tratamento', onTap: () {
                                setState(() => _status = 'Em tratamento');
                                _load();
                              }),
                              _Filter(label: 'Inativos', selected: _status == 'Inativo', onTap: () {
                                setState(() => _status = 'Inativo');
                                _load();
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_loading)
                  const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
                else if (_items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: EmptyCard(
                          icon: Icons.agriculture_outlined,
                          title: 'Nenhum animal encontrado',
                          message: 'Ajuste a busca/filtros ou cadastre um novo animal.',
                          action: 'Cadastrar animal',
                          onAction: _add,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                    sliver: SliverList.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final animal = _items[index];
                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              final changed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AnimalDetailsScreen(farm: widget.farm, animal: animal),
                                ),
                              );
                              if (changed == true) {
                                widget.onChanged();
                                await _load();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  AsyncAnimalImage(path: animal.coverPath, width: 66, height: 66),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(child: Text(animal.displayName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                                            StatusBadge(status: animal.status),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text('${animal.brinco} • ${animal.sexo} • ${animal.categoria}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${AppFormatters.weight(animal.pesoAtual)} • ${animal.lote.isEmpty ? 'Sem lote' : animal.lote}',
                                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: AppColors.muted),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

class _Filter extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Filter({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 7),
        child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
      );
}
