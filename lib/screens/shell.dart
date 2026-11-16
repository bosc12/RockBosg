import 'package:flutter/material.dart';

import '../services/updater.dart';
import 'achievements_screen.dart';
import 'capture.dart';
import 'collection.dart';
import 'home.dart';
import 'pokedex.dart';

/// Navegación principal con barra inferior.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Revisa en segundo plano si hay versión nueva (máx. 1 vez al día).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Updater.check(context);
    });
  }

  void go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onNavigate: go),
      const PokedexScreen(),
      const CollectionScreen(),
      const AchievementsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: _index == 3
          ? null
          : FloatingActionButton.extended(
              onPressed: () => startCapture(context),
              icon: const Icon(Icons.photo_camera_rounded),
              label: const Text('Capturar',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: go,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Inicio'),
          NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Pokédex'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_rounded),
              label: 'Colección'),
          NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(Icons.emoji_events_rounded),
              label: 'Logros'),
        ],
      ),
    );
  }
}
