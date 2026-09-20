import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/farm.dart';
import '../services/farm_service.dart';

class TeamScreen extends StatefulWidget {
  final Farm farm;
  const TeamScreen({super.key, required this.farm});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  List<Map<String, dynamic>> _members = const [];
  bool _loading = true;

  bool get _canManage => widget.farm.role == 'owner' || widget.farm.role == 'admin';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final members = await FarmService().members(widget.farm.id);
      if (!mounted) return;
      setState(() {
        _members = members;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao carregar equipe: $error')));
    }
  }

  Future<void> _invite() async {
    final result = await showDialog<_InviteData>(
      context: context,
      builder: (_) => const _InviteDialog(),
    );
    if (result == null) return;
    try {
      await FarmService().invite(
        farmId: widget.farm.id,
        email: result.email,
        role: result.role,
        mode: result.createDirectly ? 'create' : 'invite',
        fullName: result.fullName,
        password: result.password,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Convite/equipe atualizado com sucesso.')));
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível convidar: $error')));
    }
  }

  Future<void> _remove(Map<String, dynamic> member) async {
    final profile = Map<String, dynamic>.from(member['profiles'] as Map? ?? {});
    final name = (profile['full_name'] ?? profile['email'] ?? 'membro').toString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover acesso?'),
        content: Text('$name perderá acesso a esta fazenda.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover')),
        ],
      ),
    );
    if (ok != true) return;
    await FarmService().removeMember(widget.farm.id, profile['id'].toString());
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Equipe da fazenda')),
        floatingActionButton: _canManage
            ? FloatingActionButton.extended(
                key: const Key('inviteMemberButton'),
                onPressed: _invite,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Convidar'),
              )
            : null,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
                itemCount: _members.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final member = _members[index];
                  final profile = Map<String, dynamic>.from(member['profiles'] as Map? ?? {});
                  final role = (member['role'] ?? 'member').toString();
                  final name = (profile['full_name'] ?? '').toString();
                  final email = (profile['email'] ?? '').toString();
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.lightGreen,
                        child: Text((name.isNotEmpty ? name : email).isEmpty ? '?' : (name.isNotEmpty ? name : email)[0].toUpperCase()),
                      ),
                      title: Text(name.isEmpty ? email : name, style: const TextStyle(fontWeight: FontWeight.w900)),
                      subtitle: Text(name.isEmpty ? _role(role) : '$email • ${_role(role)}'),
                      trailing: _canManage && role != 'owner'
                          ? IconButton(onPressed: () => _remove(member), icon: const Icon(Icons.person_remove_outlined))
                          : const Icon(Icons.verified_user_outlined, color: AppColors.plantingGreen),
                    ),
                  );
                },
              ),
      );

  String _role(String role) {
    switch (role) {
      case 'owner':
        return 'Proprietário';
      case 'admin':
        return 'Administrador';
      case 'viewer':
        return 'Somente leitura';
      default:
        return 'Membro';
    }
  }
}

class _InviteData {
  final String email;
  final String role;
  final bool createDirectly;
  final String fullName;
  final String password;

  const _InviteData(
    this.email,
    this.role, {
    required this.createDirectly,
    this.fullName = '',
    this.password = '',
  });
}

class _InviteDialog extends StatefulWidget {
  const _InviteDialog();

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'member';
  bool _createDirectly = true;
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(_createDirectly ? 'Criar acesso' : 'Convidar para a fazenda'),
        content: Form(
          key: _form,
          child: SizedBox(
            width: 410,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, icon: Icon(Icons.person_add_alt_1), label: Text('Criar acesso')),
                    ButtonSegment(value: false, icon: Icon(Icons.mark_email_unread_outlined), label: Text('Enviar convite')),
                  ],
                  selected: {_createDirectly},
                  onSelectionChanged: (value) => setState(() => _createDirectly = value.first),
                ),
                const SizedBox(height: 14),
                if (_createDirectly) ...[
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nome completo'),
                    validator: (v) => v == null || v.trim().length < 2 ? 'Informe o nome.' : null,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  key: const Key('inviteEmailField'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (v) => v == null || !v.contains('@') ? 'Informe um e-mail válido.' : null,
                ),
                if (_createDirectly) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: _hidePassword,
                    decoration: InputDecoration(
                      labelText: 'Senha inicial',
                      helperText: 'Mínimo de 8 caracteres',
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _hidePassword = !_hidePassword),
                        icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                    validator: (v) {
                      if (!_createDirectly) return null;
                      return v == null || v.length < 8 ? 'Use pelo menos 8 caracteres.' : null;
                    },
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Permissão'),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                    DropdownMenuItem(value: 'member', child: Text('Membro')),
                    DropdownMenuItem(value: 'viewer', child: Text('Somente leitura')),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? _role),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            key: const Key('sendInviteButton'),
            onPressed: () {
              if (!_form.currentState!.validate()) return;
              Navigator.pop(
                context,
                _InviteData(
                  _email.text.trim(),
                  _role,
                  createDirectly: _createDirectly,
                  fullName: _name.text.trim(),
                  password: _password.text,
                ),
              );
            },
            child: Text(_createDirectly ? 'Criar acesso' : 'Enviar convite'),
          ),
        ],
      );
}
