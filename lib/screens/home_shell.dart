import 'package:flutter/material.dart';

import '../models/farm.dart';
import 'animals_screen.dart';
import 'dashboard_screen.dart';
import 'more_screen.dart';
import 'reports_screen.dart';

class HomeShell extends StatefulWidget {
  final Farm farm;
  final Future<void> Function() onSwitchFarm;
  final Future<void> Function() onFarmChanged;

  const HomeShell({
    super.key,
    required this.farm,
    required this.onSwitchFarm,
    required this.onFarmChanged,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  int _refreshTick = 0;

  void _refresh() => setState(() => _refreshTick++);

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        key: ValueKey('dashboard-$_refreshTick'),
        farm: widget.farm,
        onNavigate: (i) => setState(() => _index = i),
        onChanged: _refresh,
      ),
      AnimalsScreen(
        key: ValueKey('animals-$_refreshTick'),
        farm: widget.farm,
        onChanged: _refresh,
      ),
      ReportsScreen(
        key: ValueKey('reports-$_refreshTick'),
        farm: widget.farm,
      ),
      MoreScreen(
        key: ValueKey('more-$_refreshTick'),
        farm: widget.farm,
        onSwitchFarm: widget.onSwitchFarm,
        onChanged: () async {
          await widget.onFarmChanged();
          _refresh();
        },
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.agriculture_outlined), selectedIcon: Icon(Icons.agriculture), label: 'Animais'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'BI'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Mais'),
        ],
      ),
    );
  }
}
