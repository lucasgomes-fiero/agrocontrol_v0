import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/formatters.dart';
import '../models/animal.dart';
import '../models/farm.dart';
import '../services/animal_service.dart';

class MediaFormScreen extends StatefulWidget {
  final Farm farm;
  final Animal animal;
  final String? initialType;
  final String? healthEventId;

  const MediaFormScreen({
    super.key,
    required this.farm,
    required this.animal,
    this.initialType,
    this.healthEventId,
  });

  @override
  State<MediaFormScreen> createState() => _MediaFormScreenState();
}

class _MediaFormScreenState extends State<MediaFormScreen> {
  final _caption = TextEditingController();
  final _picker = ImagePicker();
  XFile? _photo;
  late String _type;
  DateTime _date = DateTime.now();
  bool _cover = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? 'Evolução';
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 84, maxWidth: 1800);
    if (file != null && mounted) setState(() => _photo = file);
  }

  Future<void> _choosePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pick(source);
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      helpText: 'Data da foto',
    );
    if (value != null) setState(() => _date = value);
  }

  Future<void> _save() async {
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione uma foto.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final bytes = await _photo!.readAsBytes();
      final ext = _photo!.name.contains('.') ? _photo!.name.split('.').last : 'jpg';
      await AnimalService().uploadMedia(
        farmId: widget.farm.id,
        animalId: widget.animal.id,
        bytes: bytes,
        extension: ext,
        mediaType: _type,
        takenAt: _date,
        caption: _caption.text,
        healthEventId: widget.healthEventId,
        setAsCover: _cover,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha no upload: $error')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Adicionar foto')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            InkWell(
              key: const Key('timelinePhotoPicker'),
              onTap: _choosePhoto,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 230,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _photo == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 48),
                          SizedBox(height: 10),
                          Text('Selecionar foto', style: TextStyle(fontWeight: FontWeight.w900)),
                        ],
                      )
                    : FutureBuilder(
                        future: _photo!.readAsBytes(),
                        builder: (_, snap) => snap.hasData
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.memory(snap.data!, fit: BoxFit.cover, width: double.infinity),
                              )
                            : const Center(child: CircularProgressIndicator()),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo do registro'),
              items: ['Perfil', 'Evolução', 'Nascimento', 'Vacinação', 'Saúde', 'Documento', 'Outro']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Data da foto', prefixIcon: Icon(Icons.calendar_today_outlined)),
                child: Text(AppFormatters.date(_date)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _caption,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Legenda / observação'),
            ),
            const SizedBox(height: 4),
            CheckboxListTile(
              value: _cover,
              onChanged: (v) => setState(() => _cover = v ?? false),
              contentPadding: EdgeInsets.zero,
              title: const Text('Usar como foto principal do animal'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('saveTimelinePhotoButton'),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(_saving ? 'Enviando...' : 'Salvar na linha do tempo'),
            ),
          ],
        ),
      );
}
