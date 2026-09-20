import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../models/animal.dart';
import '../models/farm.dart';
import '../services/animal_service.dart';

class WeighingFormScreen extends StatefulWidget {
  final Farm farm;
  final Animal animal;

  const WeighingFormScreen({
    super.key,
    required this.farm,
    required this.animal,
  });

  @override
  State<WeighingFormScreen> createState() => _WeighingFormScreenState();
}

class _WeighingFormScreenState extends State<WeighingFormScreen> {
  final _form = GlobalKey<FormState>();
  final _weight = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.animal.pesoAtual > 0) {
      _weight.text = widget.animal.pesoAtual.toStringAsFixed(1).replaceAll('.', ',');
    }
  }

  @override
  void dispose() {
    _weight.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Data da pesagem',
    );
    if (value != null) setState(() => _date = value);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final value = AppFormatters.decimal(_weight.text);
    if (value == null || value <= 0) return;
    setState(() => _saving = true);
    try {
      await AnimalService().addWeighing(
        farmId: widget.farm.id,
        animalId: widget.animal.id,
        weight: value,
        date: _date,
        notes: _notes.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível registrar: $error')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Nova pesagem')),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                widget.animal.displayName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              Text(widget.animal.brinco),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('weightField'),
                controller: _weight,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: const InputDecoration(
                  labelText: 'Peso *',
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                  suffixText: 'kg',
                ),
                validator: (v) {
                  final weight = AppFormatters.decimal(v ?? '');
                  return weight == null || weight <= 0 ? 'Informe um peso válido.' : null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(AppFormatters.date(_date)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Observações'),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                key: const Key('saveWeighingButton'),
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(_saving ? 'Salvando...' : 'Registrar pesagem'),
              ),
            ],
          ),
        ),
      );
}
