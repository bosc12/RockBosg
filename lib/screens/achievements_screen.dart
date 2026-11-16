import 'package:flutter/material.dart';

import '../data/achievements.dart';
import '../data/catalog.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final st = state.stats;
    final cs = Theme.of(context).colorScheme;
    final unlocked = achievements.where((a) => a.unlocked(st)).length;
    final span = st.xpForNextLevel - st.xpForThisLevel;
    final into = st.xp - st.xpForThisLevel;

    return Scaffold(
      appBar: AppBar(title: const Text('Logros')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Brand.slate, Color(0xFF3A2E10)],
              ),
            ),
            child: Row(children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Brand.gold, width: 3),
                ),
                alignment: Alignment.center,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('NIVEL',
                      style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          letterSpacing: 1.5)),
                  Text('${st.level}',
                      style: const TextStyle(
                          color: Brand.gold,
                          fontSize: 28,
                          fontWeight: FontWeight.w900)),
                ]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(st.rank,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text('${st.xp} XP en total',
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: span == 0 ? 0 : into / span,
                          minHeight: 9,
                          color: Brand.gold,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                          'Faltan ${span - into} XP para el nivel ${st.level + 1}',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12.5)),
                    ]),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Text(
            'Ganas XP por cada piedra (+10), cada especie nueva (+25, más si es rara) y cada insignia (+50).',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          const SectionTitle('Progreso por tipo'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                for (final k in kindShort.keys) ...[
                  _KindProgress(
                    kind: k,
                    found: st.byKind[k]!,
                    total: catalog.where((m) => m.kind == k).length,
                  ),
                  if (k != kindShort.keys.last) const SizedBox(height: 12),
                ],
              ]),
            ),
          ),
          SectionTitle('Insignias',
              trailing: Text('$unlocked / ${achievements.length}',
                  style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16))),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.92,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, i) =>
                _BadgeTile(a: achievements[i], stats: st),
          ),
        ],
      ),
    );
  }
}

class _KindProgress extends StatelessWidget {
  const _KindProgress(
      {required this.kind, required this.found, required this.total});

  final String kind;
  final int found;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = Brand.kindColor(kind);
    return Row(children: [
      Icon(Brand.kindIcon(kind), color: c),
      const SizedBox(width: 10),
      SizedBox(
          width: 108,
          child: Text(kindShort[kind]!,
              style: const TextStyle(fontWeight: FontWeight.w700))),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : found / total,
            minHeight: 9,
            color: c,
            backgroundColor: c.withOpacity(0.15),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Text('$found/$total',
          style: const TextStyle(fontWeight: FontWeight.w800)),
    ]);
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.a, required this.stats});

  final Achievement a;
  final Stats stats;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = a.progress(stats).clamp(0, a.goal);
    final done = p >= a.goal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? Brand.gold.withOpacity(0.2) : cs.surfaceContainer,
            ),
            child: Icon(done ? a.icon : Icons.lock_outline_rounded,
                color: done ? Brand.gold : cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(a.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
          const SizedBox(height: 2),
          Expanded(
            child: Text(a.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: cs.onSurfaceVariant, fontSize: 12.5, height: 1.25)),
          ),
          if (!done) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: p / a.goal,
                minHeight: 6,
                backgroundColor: cs.surfaceContainer,
              ),
            ),
            const SizedBox(height: 3),
            Text('$p / ${a.goal}',
                style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
          ] else
            const Text('¡Conseguida!',
                style: TextStyle(
                    color: Brand.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5)),
        ]),
      ),
    );
  }
}
