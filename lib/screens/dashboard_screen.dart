import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/animal.dart';
import '../models/bi_models.dart';
import '../models/farm.dart';
import '../services/animal_service.dart';
import '../services/bi_service.dart';
import '../widgets/async_animal_image.dart';
import '../widgets/brand.dart';
import '../widgets/animal_picker.dart';
import 'animal_details_screen.dart';
import 'animal_form_screen.dart';
import 'health_form_screen.dart';
import 'weighing_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Farm farm;
  final ValueChanged<int> onNavigate;
  final VoidCallback onChanged;

  const DashboardScreen({
    super.key,
    required this.farm,
    required this.onNavigate,
    required this.onChanged,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats _stats = const DashboardStats();
  List<Animal> _animals = const [];
  bool _loading = true;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        BiService().load(widget.farm.id),
        AnimalService().listAnimals(widget.farm.id),
      ]);
      if (!mounted) return;
      final bi = results[0] as BiSnapshot;
      final animals = results[1] as List<Animal>;
      setState(() {
        _stats = bi.stats;
        _animals = animals.take(4).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao carregar dashboard: $error')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _openNewAnimal() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AnimalFormScreen(farm: widget.farm)),
    );
    if (changed == true) {
      widget.onChanged();
      await _load();
    }
  }

  Future<void> _openWeighing() async {
    final animal = await AnimalPicker.show(context, widget.farm);
    if (!mounted || animal == null) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => WeighingFormScreen(farm: widget.farm, animal: animal)),
    );
    if (changed == true) {
      widget.onChanged();
      await _load();
    }
  }

  Future<void> _openHealth() async {
    final animal = await AnimalPicker.show(context, widget.farm);
    if (!mounted || animal == null) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => HealthFormScreen(farm: widget.farm, animal: animal)),
    );
    if (changed == true) {
      widget.onChanged();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                const Expanded(child: AgroWordmark(height: 48)),
                IconButton.filledTonal(
                  tooltip: 'Atualizar',
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dashboard', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(
                        widget.farm.name,
                        style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (widget.farm.state?.isNotEmpty == true)
                  Chip(
                    avatar: const Icon(Icons.location_on_outlined, size: 17),
                    label: Text(widget.farm.state!),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _Hero(stats: _stats, farmName: widget.farm.name),
            const SizedBox(height: 14),
            if (_loading)
              const LinearProgressIndicator(minHeight: 2)
            else
              _StatsGrid(stats: _stats),
            const SizedBox(height: 24),
            const SectionTitle('Ações rápidas'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    key: const Key('dashboardNewAnimal'),
                    icon: Icons.add_circle_outline,
                    label: 'Novo animal',
                    color: AppColors.plantingGreen,
                    onTap: _openNewAnimal,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _QuickAction(
                    key: const Key('dashboardWeighing'),
                    icon: Icons.monitor_weight_outlined,
                    label: 'Pesagem',
                    color: AppColors.sky,
                    onTap: _openWeighing,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _QuickAction(
                    key: const Key('dashboardHealth'),
                    icon: Icons.vaccines_outlined,
                    label: 'Saúde',
                    color: AppColors.earth,
                    onTap: _openHealth,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _QuickAction(
                    key: const Key('dashboardBi'),
                    icon: Icons.insights_outlined,
                    label: 'Abrir BI',
                    color: AppColors.warning,
                    onTap: () => widget.onNavigate(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionTitle('Animais recentes', action: 'Ver todos', onAction: () => widget.onNavigate(1)),
            const SizedBox(height: 10),
            if (!_loading && _animals.isEmpty)
              EmptyCard(
                icon: Icons.agriculture_outlined,
                title: 'Seu rebanho começa aqui',
                message: 'Cadastre o primeiro animal e acompanhe peso, saúde e fotos ao longo do tempo.',
                action: 'Cadastrar animal',
                onAction: _openNewAnimal,
              )
            else
              ..._animals.map((animal) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Card(
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
                              AsyncAnimalImage(path: animal.coverPath, width: 62, height: 62),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(animal.displayName, style: const TextStyle(fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${animal.brinco} • ${animal.raca.isEmpty ? animal.especie : animal.raca}',
                                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                    ),
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
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final DashboardStats stats;
  final String farmName;

  const _Hero({required this.stats, required this.farmName});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.darkGreen, AppColors.forest, Color(0xFF2E7A4C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -34,
              top: -48,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .045),
                ),
              ),
            ),
            Positioned(
              right: 42,
              bottom: -52,
              child: Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lime.withValues(alpha: .07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'VISÃO DO REBANHO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'Manejo que vira resultado.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    stats.animals == 0
                        ? 'Cadastre animais para liberar os indicadores.'
                        : '${stats.animals} animais sob controle em $farmName.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .84),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
        children: [
          _Stat(icon: Icons.agriculture, value: '${stats.animals}', label: 'Animais', color: AppColors.plantingGreen),
          _Stat(icon: Icons.monitor_weight_outlined, value: AppFormatters.weight(stats.avgWeight), label: 'Peso médio', color: AppColors.sky),
          _Stat(icon: Icons.healing_outlined, value: '${stats.treatment}', label: 'Em tratamento', color: AppColors.earth),
          _Stat(icon: Icons.vaccines_outlined, value: '${stats.vaccinesDue}', label: 'Vacinas em 30 dias', color: AppColors.warning),
        ],
      );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _Stat({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .11),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: .18)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: .16),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
                  const SizedBox(height: 2),
                  Text(label, maxLines: 2, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({super.key, required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 82,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: .16)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 25),
              const SizedBox(height: 7),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10.5)),
            ],
          ),
        ),
      );
}
