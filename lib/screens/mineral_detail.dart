import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'capture.dart';
import 'specimen_detail.dart';

/// Ficha de una especie del catálogo.
class MineralDetailScreen extends StatelessWidget {
  const MineralDetailScreen({super.key, required this.mineral});

  final Mineral mineral;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final mine = state.specimensOf(mineral.id);
    final discovered = mine.isNotEmpty;
    final cs = Theme.of(context).colorScheme;
    final color = Brand.forMineral(mineral);
    final geo = state.isGeologist;

    return Scaffold(
      appBar: AppBar(title: Text(mineral.number)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.28), color.withOpacity(0.06)],
              ),
            ),
            child: Row(children: [
              MineralAvatar(mineral: mineral, size: 84),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mineral.name,
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      KindChip(kind: mineral.kind),
                      const SizedBox(height: 8),
                      Row(children: [
                        RarityStars(rarity: mineral.rarity),
                        const SizedBox(width: 6),
                        Text(rarityLabels[mineral.rarity]!,
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 13)),
                      ]),
                    ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: discovered
                  ? cs.primary.withOpacity(0.12)
                  : cs.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Icon(
                  discovered
                      ? Icons.check_circle_rounded
                      : Icons.lock_outline_rounded,
                  color: discovered ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  discovered
                      ? '¡Descubierta! Tienes ${mine.length} ${mine.length == 1 ? 'ejemplar' : 'ejemplares'}.'
                      : 'Aún no la capturas. ¡Sal a buscarla!',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ]),
          ),
          const SectionTitle('¿Sabías que…?'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.lightbulb_rounded, color: Brand.gold),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(mineral.fact,
                        style: const TextStyle(fontSize: 15.5, height: 1.4))),
              ]),
            ),
          ),
          SectionTitle(geo ? 'Ficha técnica' : 'Cómo reconocerla'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(children: [
                if (geo)
                  PropRow('Grupo', mineral.group, icon: Icons.category_rounded),
                if (geo && mineral.formula != null)
                  PropRow('Fórmula', mineral.formula!,
                      icon: Icons.science_rounded),
                PropRow('Dureza',
                    '${mineral.mohsText} Mohs${mineral.isRock ? ' (aprox.)' : ''}',
                    icon: Icons.straighten_rounded),
                PropRow('Color', mineral.colors, icon: Icons.palette_rounded),
                PropRow(mineral.isRock ? 'Textura' : 'Brillo', mineral.luster,
                    icon: mineral.isRock
                        ? Icons.texture_rounded
                        : Icons.flare_rounded),
                if (mineral.streak != null)
                  PropRow('Raya', mineral.streak!, icon: Icons.brush_rounded),
                if (geo && mineral.system != null)
                  PropRow('Sistema', mineral.system!,
                      icon: Icons.hexagon_outlined),
                if (!geo && !mineral.isRock)
                  PropRow('Grupo', mineral.group, icon: Icons.category_rounded),
              ]),
            ),
          ),
          if (!geo) ...[
            const SizedBox(height: 8),
            Text(
              _hardnessHint(mineral.mohsMax),
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13.5),
            ),
          ],
          if (discovered) ...[
            const SectionTitle('Mis ejemplares'),
            for (final s in mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    leading: SpecimenThumb(specimen: s, size: 52),
                    title: Text(s.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(s.place.isEmpty ? 'Sin lugar' : s.place,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SpecimenDetailScreen(id: s.id))),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => startCapture(context, preset: mineral),
            icon: const Icon(Icons.photo_camera_rounded),
            label: Text(
                discovered ? 'Agregar otro ejemplar' : 'Capturar esta especie'),
          ),
        ],
      ),
    );
  }

  static String _hardnessHint(double mohs) {
    if (mohs <= 2.5) return '💡 Tan blanda que se puede rayar con la uña.';
    if (mohs <= 3.5) {
      return '💡 Se raya con una moneda de cobre, pero no con la uña.';
    }
    if (mohs < 5.5) return '💡 Se raya con una navaja de acero.';
    if (mohs < 7) return '💡 No se raya con navaja; con suerte raya el vidrio.';
    return '💡 Muy dura: raya el vidrio y el acero sin problema.';
  }
}
