import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/exchange.dart';
import '../state.dart';
import '../widgets/common.dart';
import 'capture.dart';
import 'mineral_detail.dart';

/// Ficha de una piedra de la colección.
class SpecimenDetailScreen extends StatefulWidget {
  const SpecimenDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<SpecimenDetailScreen> createState() => _SpecimenDetailScreenState();
}

class _SpecimenDetailScreenState extends State<SpecimenDetailScreen> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.specimens.where((e) => e.id == widget.id).firstOrNull;
    if (s == null) return const Scaffold(body: SizedBox()); // recién borrada

    final cs = Theme.of(context).colorScheme;
    final m = s.mineral;
    final df = DateFormat("d 'de' MMMM 'de' y", 'es');

    return Scaffold(
      appBar: AppBar(
        title: Text(m?.number ?? 'Mi piedra'),
        actions: [
          IconButton(
            tooltip: s.favorite ? 'Quitar de favoritas' : 'Marcar favorita',
            onPressed: () {
              s.favorite = !s.favorite;
              state.save(s);
            },
            icon: Icon(
                s.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: s.favorite ? Colors.amber : null),
          ),
          IconButton(
            tooltip: 'Compartir',
            onPressed: () => Exchange.share(context, [s], single: true),
            icon: const Icon(Icons.share_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'edit') {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SpecimenEditScreen(existing: s)));
              } else if (v == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('¿Eliminar esta piedra?'),
                    content: Text(
                        'Se borrará "${s.displayName}" y sus fotos de este teléfono.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar')),
                      FilledButton(
                        style:
                            FilledButton.styleFrom(backgroundColor: cs.error),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  Navigator.pop(context);
                  await state.remove(s);
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                      leading: Icon(Icons.edit_rounded),
                      title: Text('Editar'))),
              PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                      leading: Icon(Icons.delete_outline_rounded),
                      title: Text('Eliminar'))),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          // Fotos
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 1,
              child: s.photos.isEmpty
                  ? Container(
                      color: cs.surfaceContainer,
                      child: Center(
                        child: m != null
                            ? MineralAvatar(mineral: m, size: 120)
                            : const Icon(Icons.image_not_supported_rounded,
                                size: 60),
                      ),
                    )
                  : Stack(children: [
                      PageView.builder(
                        itemCount: s.photos.length,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    _PhotoViewer(files: s.photos, initial: i)),
                          ),
                          child: Image.file(state.db.photoFile(s.photos[i]),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image_rounded))),
                        ),
                      ),
                      if (s.photos.length > 1)
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              s.photos.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                width: i == _page ? 18 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: i == _page
                                      ? Colors.white
                                      : Colors.white54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ]),
            ),
          ),
          const SizedBox(height: 16),
          Text(s.displayName,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (m != null) KindChip(kind: m.kind),
                if (m != null) RarityStars(rarity: m.rarity),
                if (s.origin != null)
                  Chip(
                    avatar: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: Text('Compartida por ${s.origin}'),
                    visualDensity: VisualDensity.compact,
                  ),
              ]),

          if (m != null) ...[
            const SizedBox(height: 12),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: MineralAvatar(mineral: m, size: 42),
                title: Text('${m.number} · ${m.name}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Ver ficha en la Pokédex'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => MineralDetailScreen(mineral: m))),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: Icon(Icons.help_outline_rounded, color: cs.error),
                title: const Text('Sin identificar',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Toca para elegir qué es en el catálogo'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SpecimenEditScreen(existing: s))),
              ),
            ),
          ],

          const SectionTitle('Hallazgo'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(children: [
                PropRow('Fecha', df.format(s.foundAt),
                    icon: Icons.event_rounded),
                PropRow('Lugar', s.place.isEmpty ? '—' : s.place,
                    icon: Icons.place_rounded),
                if (s.hasLocation)
                  PropRow('GPS',
                      '${s.lat!.toStringAsFixed(5)}, ${s.lng!.toStringAsFixed(5)}',
                      icon: Icons.my_location_rounded),
              ]),
            ),
          ),
          if (s.hasLocation) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _openMap(s.lat!, s.lng!, s.displayName),
              icon: const Icon(Icons.map_rounded),
              label: const Text('Ver en el mapa'),
            ),
          ],

          if ([s.mohs, s.streak, s.color, s.luster, s.weight, s.size]
              .any((e) => e.isNotEmpty)) ...[
            const SectionTitle('Datos científicos'),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(children: [
                  if (s.mohs.isNotEmpty)
                    PropRow('Dureza', '${s.mohs} Mohs',
                        icon: Icons.straighten_rounded),
                  if (s.streak.isNotEmpty)
                    PropRow('Raya', s.streak, icon: Icons.brush_rounded),
                  if (s.color.isNotEmpty)
                    PropRow('Color', s.color, icon: Icons.palette_rounded),
                  if (s.luster.isNotEmpty)
                    PropRow(m?.isRock == true ? 'Textura' : 'Brillo', s.luster,
                        icon: Icons.flare_rounded),
                  if (s.weight.isNotEmpty)
                    PropRow('Peso', s.weight, icon: Icons.scale_rounded),
                  if (s.size.isNotEmpty)
                    PropRow('Tamaño', s.size, icon: Icons.aspect_ratio_rounded),
                ]),
              ),
            ),
          ],

          if (s.notes.isNotEmpty) ...[
            const SectionTitle('Notas'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(s.notes,
                    style: const TextStyle(fontSize: 15.5, height: 1.4)),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => SpecimenEditScreen(existing: s))),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Editar'),
          ),
        ],
      ),
    );
  }
}

Future<void> _openMap(double lat, double lng, String label) async {
  final geo =
      Uri.parse('geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(label)})');
  try {
    if (await launchUrl(geo, mode: LaunchMode.externalApplication)) return;
  } catch (_) {}
  await launchUrl(Uri.parse('https://maps.google.com/?q=$lat,$lng'),
      mode: LaunchMode.externalApplication);
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.files, required this.initial});

  final List<String> files;
  final int initial;

  @override
  Widget build(BuildContext context) {
    final db = AppScope.read(context).db;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initial),
        itemCount: files.length,
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 6,
          child: Center(child: Image.file(db.photoFile(files[i]))),
        ),
      ),
    );
  }
}
