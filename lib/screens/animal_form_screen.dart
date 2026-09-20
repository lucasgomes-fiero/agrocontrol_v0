import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/animal.dart';
import '../models/farm.dart';
import '../services/animal_service.dart';

class AnimalFormScreen extends StatefulWidget {
  final Farm farm;
  final Animal? animal;

  const AnimalFormScreen({
    super.key,
    required this.farm,
    this.animal,
  });

  @override
  State<AnimalFormScreen> createState() => _AnimalFormScreenState();
}

class _AnimalFormScreenState extends State<AnimalFormScreen> {
  final _form = GlobalKey<FormState>();
  final _brinco = TextEditingController();
  final _nome = TextEditingController();
  final _raca = TextEditingController();
  final _lote = TextEditingController();
  final _origem = TextEditingController();
  final _obs = TextEditingController();
  final _picker = ImagePicker();

  String _especie = 'Bovino';
  String _sexo = 'Macho';
  String _categoria = 'Adulto';
  String _status = 'Ativo';
  DateTime? _birth;
  XFile? _photo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.animal;
    if (a != null) {
      _brinco.text = a.brinco;
      _nome.text = a.nome;
      _raca.text = a.raca;
      _lote.text = a.lote;
      _origem.text = a.origem;
      _obs.text = a.observacao;
      _especie = a.especie;
      _sexo = a.sexo;
      _categoria = a.categoria;
      _status = a.status;
      _birth = a.dataNascimento;
    }
  }

  @override
  void dispose() {
    _brinco.dispose();
    _nome.dispose();
    _raca.dispose();
    _lote.dispose();
    _origem.dispose();
    _obs.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Câmera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final photo = await _picker.pickImage(source: source, imageQuality: 84, maxWidth: 1800);
    if (photo != null && mounted) setState(() => _photo = photo);
  }

  Future<void> _pickBirth() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      helpText: 'Data de nascimento',
    );
    if (value != null) setState(() => _birth = value);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final animal = await AnimalService().saveAnimal(
        id: widget.animal?.id,
        farmId: widget.farm.id,
        brinco: _brinco.text,
        nome: _nome.text,
        especie: _especie,
        raca: _raca.text,
        sexo: _sexo,
        categoria: _categoria,
        dataNascimento: _birth,
        lote: _lote.text,
        origem: _origem.text,
        status: _status,
        observacao: _obs.text,
      );
      if (_photo != null) {
        final bytes = await _photo!.readAsBytes();
        final ext = _photo!.name.contains('.') ? _photo!.name.split('.').last : 'jpg';
        await AnimalService().uploadMedia(
          farmId: widget.farm.id,
          animalId: animal.id,
          bytes: bytes,
          extension: ext,
          mediaType: _birth != null ? 'Nascimento' : 'Perfil',
          takenAt: _birth ?? DateTime.now(),
          caption: _birth != null ? 'Registro de nascimento' : 'Foto de cadastro',
          setAsCover: true,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o animal: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.animal == null ? 'Cadastrar animal' : 'Editar animal')),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              InkWell(
                key: const Key('animalPhotoPicker'),
                onTap: _pickPhoto,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 132,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.lightGreen, AppColors.sand]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _photo == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, color: AppColors.darkGreen, size: 34),
                            SizedBox(height: 8),
                            Text('Adicionar foto do animal', style: TextStyle(fontWeight: FontWeight.w900)),
                            Text('Pode ser foto de cadastro ou nascimento', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                          ],
                        )
                      : FutureBuilder(
                          future: _photo!.readAsBytes(),
                          builder: (context, snapshot) => snapshot.hasData
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.memory(snapshot.data!, fit: BoxFit.cover, width: double.infinity),
                                )
                              : const Center(child: CircularProgressIndicator()),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                key: const Key('animalTagField'),
                controller: _brinco,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Brinco *', prefixIcon: Icon(Icons.sell_outlined)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe o brinco.' : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nome,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nome', prefixIcon: Icon(Icons.badge_outlined)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _especie,
                      decoration: const InputDecoration(labelText: 'Espécie'),
                      items: ['Bovino', 'Bubalino', 'Ovino', 'Caprino']
                          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) => setState(() => _especie = v ?? _especie),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _raca, decoration: const InputDecoration(labelText: 'Raça'))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _sexo,
                      decoration: const InputDecoration(labelText: 'Sexo'),
                      items: ['Macho', 'Fêmea'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: (v) => setState(() => _sexo = v ?? _sexo),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _categoria,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: ['Bezerro', 'Novilho', 'Novilha', 'Vaca', 'Touro', 'Adulto']
                          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) => setState(() => _categoria = v ?? _categoria),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickBirth,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data de nascimento',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  child: Text(AppFormatters.date(_birth)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _lote, decoration: const InputDecoration(labelText: 'Lote'))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _origem, decoration: const InputDecoration(labelText: 'Origem'))),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.circle_outlined)),
                items: ['Ativo', 'Em tratamento', 'Inativo']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _obs,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                key: const Key('animalSaveButton'),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check),
                label: Text(_saving ? 'Salvando...' : 'Salvar animal'),
              ),
            ],
          ),
        ),
      );
}
