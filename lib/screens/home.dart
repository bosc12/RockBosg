import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'mineral_detail.dart';
import 'settings.dart';
import 'specimen_detail.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final void Function(int) onNavigate;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final st = state.stats;
    final cs = Theme.of(context).colorScheme;
    final dayIndex =
        DateTime.now().difference(DateTime(2024)).inDays % catalog.length;
    final daily = catalog[dayIndex];
    final recent = state.specimens.take(10).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Row(children: [
            const AppLogo(size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FamilyTitle('Colección', size: 24),
                    Text('Hola, ${state.userName ?? ''} 👋',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 15)),
                  ]),
            ),
            IconButton.filledTonal(
              tooltip: 'Ajustes',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
              icon: const Icon(Icons.settings_rounded),
            ),
          ]),
          const SizedBox(height: 18),

          // Tarjeta principal: progreso de la Pokédex
          _HeroCard(
            onTap: () => onNavigate(1),
            title: 'Pokédex Gómez',
            value: '${st.species.length} / ${catalog.length}',
            caption: 'especies descubiertas',
            progress: st.completion,
          ),
          const SizedBox(height: 12),

          Row(children: [
            Expanded(
                child: _StatTile(
                    icon: Icons.inventory_2_rounded,
                    value: '${st.total}',
                    label: 'piedras',
                    onTap: () => onNavigate(2))),
            const SizedBox(width: 10),
            Expanded(
                child: _StatTile(
                    icon: Icons.photo_library_rounded,
                    value: '${st.photos}',
                    label: 'fotos')),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: state.isGeologist
                    ? Icons.place_rounded
                    : Icons.military_tech_rounded,
                value: state.isGeologist ? '${st.withGps}' : 'Nv. ${st.level}',
                label: state.isGeologist ? 'con GPS' : 'nivel',
                onTap: () => onNavigate(3),
              ),
            ),
          ]),

          if (!state.isGeologist) ...[
            const SizedBox(height: 12),
            _LevelCard(onTap: () => onNavigate(3)),
          ],

          SectionTitle('Últimas capturas',
              trailing: recent.isEmpty
                  ? null
                  : TextButton(
                      onPressed: () => onNavigate(2),
                      child: const Text('Ver todas'))),
          if (recent.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Icon(Icons.landscape_rounded, size: 44, color: cs.primary),
                  const SizedBox(height: 8),
                  const Text('Aún no hay piedras',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Toca "Capturar" para fotografiar tu primera piedra.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ]),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recent.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final s = recent[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SpecimenDetailScreen(id: s.id))),
                    child: SizedBox(
                      width: 116,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SpecimenThumb(specimen: s, size: 116, radius: 16),
                            const SizedBox(height: 6),
                            Text(s.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ]),
                    ),
                  );
                },
              ),
            ),

          const SectionTitle('Dato del día'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => MineralDetailScreen(mineral: daily))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MineralAvatar(mineral: daily, size: 52),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${daily.number} · ${daily.name}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text(daily.fact,
                                  style: const TextStyle(height: 1.35)),
                            ]),
                      ),
                    ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.onTap,
    required this.title,
    required this.value,
    required this.caption,
    required this.progress,
  });

  final VoidCallback onTap;
  final String title;
  final String value;
  final String caption;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Brand.slate, Color(0xFF0E3A4C)],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.grid_view_rounded, color: Brand.cyan),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            ]),
            const SizedBox(height: 14),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1)),
            Text(caption,
                style: const TextStyle(color: Colors.white70, fontSize: 15)),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                color: Brand.cyan,
                backgroundColor: Colors.white12,
              ),
            ),
            const SizedBox(height: 6),
            Text('${(progress * 100).toStringAsFixed(0)}% completado',
                style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.icon,
      required this.value,
      required this.label,
      this.onTap});

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: cs.primary, size: 22),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900)),
            ),
            Text(label,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context).stats;
    final cs = Theme.of(context).colorScheme;
    final span = st.xpForNextLevel - st.xpForThisLevel;
    final into = st.xp - st.xpForThisLevel;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Brand.gold.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text('${st.level}',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Brand.gold)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(st.rank,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: span == 0 ? 0 : into / span,
                        minHeight: 8,
                        color: Brand.gold,
                        backgroundColor: cs.surfaceContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$into / $span XP para el nivel ${st.level + 1}',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12.5)),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }
}
