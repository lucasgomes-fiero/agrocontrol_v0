import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/farm.dart';
import '../services/farm_service.dart';
import '../widgets/brand.dart';
import 'home_shell.dart';

class FarmGate extends StatefulWidget {
  const FarmGate({super.key});

  @override
  State<FarmGate> createState() => _FarmGateState();
}

class _FarmGateState extends State<FarmGate> {
  final _service = FarmService();
  List<Farm> _farms = const [];
  Farm? _active;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final farms = await _service.listFarms();
      if (!mounted) return;
      setState(() {
        _farms = farms;
        _active ??= farms.isEmpty ? null : farms.first;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível carregar as fazendas: $error')),
      );
    }
  }

  Future<void> _createFarm() async {
    final result = await showDialog<Farm>(
      context: context,
      builder: (_) => const _CreateFarmDialog(),
    );
    if (result != null) {
      await _load();
      if (!mounted) return;
      setState(() => _active = result);
    }
  }

  Future<void> _chooseFarm() async {
    final farm = await showModalBottomSheet<Farm>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            const Text('Trocar fazenda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ..._farms.map((f) => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.landscape_outlined)),
                  title: Text(f.name),
                  subtitle: Text([f.city, f.state].whereType<String>().where((e) => e.isNotEmpty).join(' • ')),
                  trailing: f.id == _active?.id ? const Icon(Icons.check, color: AppColors.plantingGreen) : null,
                  onTap: () => Navigator.pop(context, f),
                )),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.add)),
              title: const Text('Cadastrar nova fazenda'),
              onTap: () {
                Navigator.pop(context);
                _createFarm();
              },
            ),
          ],
        ),
      ),
    );
    if (farm != null) setState(() => _active = farm);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_active == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AgroMark(size: 96),
                      const SizedBox(height: 18),
                      const Text('Cadastre sua primeira fazenda', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      const Text(
                        'Cada fazenda possui dados, equipe, animais e indicadores separados.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        key: const Key('createFirstFarmButton'),
                        onPressed: _createFarm,
                        icon: const Icon(Icons.add),
                        label: const Text('Cadastrar fazenda'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return HomeShell(
      key: ValueKey(_active!.id),
      farm: _active!,
      onSwitchFarm: _chooseFarm,
      onFarmChanged: _load,
    );
  }
}

class _CreateFarmDialog extends StatefulWidget {
  const _CreateFarmDialog();

  @override
  State<_CreateFarmDialog> createState() => _CreateFarmDialogState();
}

class _CreateFarmDialogState extends State<_CreateFarmDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _state.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final farm = await FarmService().createFarm(
        name: _name.text,
        city: _city.text,
        state: _state.text,
      );
      if (mounted) Navigator.pop(context, farm);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível cadastrar: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Nova fazenda'),
        content: Form(
          key: _form,
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nome da fazenda'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome.' : null,
                ),
                const SizedBox(height: 12),
                TextField(controller: _city, decoration: const InputDecoration(labelText: 'Cidade')),
                const SizedBox(height: 12),
                TextField(
                  controller: _state,
                  maxLength: 2,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'UF', counterText: ''),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: _loading ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: _loading ? null : _save, child: Text(_loading ? 'Salvando...' : 'Salvar')),
        ],
      );
}
