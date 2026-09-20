import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/farm.dart';
import '../services/auth_service.dart';
import '../widgets/brand.dart';
import 'team_screen.dart';

class MoreScreen extends StatelessWidget {
  final Farm farm;
  final Future<void> Function() onSwitchFarm;
  final Future<void> Function() onChanged;

  const MoreScreen({
    super.key,
    required this.farm,
    required this.onSwitchFarm,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          children: [
            const AgroWordmark(height: 46),
            const SizedBox(height: 20),
            const Text('Mais', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.lightGreen, AppColors.sand]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const AgroMark(size: 72),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(farm.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(
                          [farm.city, farm.state].whereType<String>().where((e) => e.isNotEmpty).join(' • '),
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 5),
                        Text('Seu perfil: ${_role(farm.role)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    key: const Key('switchFarmButton'),
                    leading: const _MenuIcon(Icons.swap_horiz),
                    title: const Text('Trocar fazenda', style: TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: const Text('Alternar entre operações sem misturar os dados'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onSwitchFarm(),
                  ),
                  const Divider(height: 1, indent: 66),
                  ListTile(
                    key: const Key('teamButton'),
                    leading: const _MenuIcon(Icons.groups_outlined),
                    title: const Text('Equipe e acessos', style: TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: const Text('Convidar usuários e gerenciar permissões'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TeamScreen(farm: farm)),
                      );
                      await onChanged();
                    },
                  ),
                  const Divider(height: 1, indent: 66),
                  const ListTile(
                    leading: _MenuIcon(Icons.cloud_done_outlined),
                    title: Text('Nuvem Supabase', style: TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text('Dados e fotos sincronizados com segurança'),
                    trailing: Icon(Icons.check_circle, color: AppColors.plantingGreen),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                key: const Key('logoutButton'),
                leading: const _MenuIcon(Icons.logout),
                title: const Text('Sair da conta', style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text('Encerrar esta sessão'),
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sair da conta?'),
                      content: const Text('Você precisará entrar novamente para acessar as fazendas.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sair')),
                      ],
                    ),
                  );
                  if (ok == true) await AuthService().signOut();
                },
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              'AgroControl SaaS • v2.0',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      );

  static String _role(String role) {
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

class _MenuIcon extends StatelessWidget {
  final IconData icon;
  const _MenuIcon(this.icon);

  @override
  Widget build(BuildContext context) => CircleAvatar(
        backgroundColor: AppColors.lightGreen,
        child: Icon(icon, color: AppColors.darkGreen),
      );
}
