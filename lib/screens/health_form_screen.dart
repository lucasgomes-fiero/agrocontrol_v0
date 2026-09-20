import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/formatters.dart';
import '../models/animal.dart';
import '../models/farm.dart';
import '../services/animal_service.dart';

class HealthFormScreen extends StatefulWidget {
  final Farm farm;
  final Animal animal;

  const HealthFormScreen({
    super.key,
    required this.farm,
    required this.animal,
  });

  @override
  State<HealthFormScreen> createState() => _HealthFormScreenState();
}

class _HealthFormScreenState extends State<HealthFormScreen> {
  final _form = GlobalKey<FormState>();
  final _product = TextEditingController();
  final _notes = TextEditingController();
  final _picker = ImagePicker();
  String _type = 'Vacina';
  DateTime _date = DateTime.now();
  DateTime? _next;
  XFile? _photo;
  bool _saving = false;

  @override
  void dispose() {
    _product.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<DateTime?> _datePicker(DateTime initial, String help) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: help,
    );
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Câmera'), onTap: () => Navigator.pop(context, ImageSource.camera)),
            ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Galeria'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
          ],
        ),
      ),
    );
    if (source == null) return;
    final photo = await _picker.pickImage(source: source, imageQuality: 84, maxWidth: 1800);
    if (photo != null && mounted) setState(() => _photo = photo);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final eventId = await AnimalService().addHealthEvent(
        farmId: widget.farm.id,
        animalId: widget.animal.id,
        type: _type,
        product: _product.text,
        date: _date,
        nextDueDate: _next,
        notes: _notes.text,
      );
      if (_photo != null) {
        final bytes = await _photo!.readAsBytes();
        final ext = _photo!.name.contains('.') ? _photo!.name.split('.').last : 'jpg';
        await AnimalService().uploadMedia(
          farmId: widget.farm.id,
          animalId: widget.animal.id,
          bytes: bytes,
          extension: ext,
          mediaType: _type == 'Vacina' ? 'Vacinação' : 'Saúde',
          takenAt: _date,
          caption: '$_type • ${_product.text.trim()}',
          healthEventId: eventId,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível salvar: $error')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Saúde e manejo')),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            children: [
              Text(widget.animal.displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              Text(widget.animal.brinco),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo', prefixIcon: Icon(Icons.medical_services_outlined)),
                items: ['Vacina', 'Vermífugo', 'Medicamento', 'Tratamento', 'Manejo', 'Nascimento', 'Outro']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('healthProductField'),
                controller: _product,
                decoration: const InputDecoration(labelText: 'Produto / procedimento *', prefixIcon: Icon(Icons.vaccines_outlined)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe o produto ou procedimento.' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final value = await _datePicker(_date, 'Data do registro');
                  if (value != null) setState(() => _date = value);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Data', prefixIcon: Icon(Icons.calendar_today_outlined)),
                  child: Text(AppFormatters.date(_date)),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final value = await _datePicker(_next ?? DateTime.now().add(const Duration(days: 30)), 'Próxima dose / vencimento');
                  if (value != null) setState(() => _next = value);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Próxima dose / vencimento',
                    prefixIcon: const Icon(Icons.event_repeat_outlined),
                    suffixIcon: _next == null ? null : IconButton(onPressed: () => setState(() => _next = null), icon: const Icon(Icons.close)),
                  ),
                  child: Text(AppFormatters.date(_next)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Observações'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('healthPhotoButton'),
                onPressed: _pickPhoto,
                icon: Icon(_photo == null ? Icons.add_a_photo_outlined : Icons.check_circle_outline),
                label: Text(_photo == null ? 'Anexar foto/comprovante' : 'Foto anexada • trocar'),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const Key('saveHealthButton'),
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(_saving ? 'Salvando...' : 'Salvar registro'),
              ),
            ],
          ),
        ),
      );
}
