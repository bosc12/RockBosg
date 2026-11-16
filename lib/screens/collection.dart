import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/specimen.dart';
import '../state.dart';
import '../widgets/common.dart';
import 'specimen_detail.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

enum _Sort { recent, found, name, number }

class _CollectionScreenState extends State<CollectionScreen> {
  String _query = '';
  _Sort _sort = _Sort.recent;
  bool _onlyFav = false;

  List<Specimen> _apply(List<Specimen> all) {
    final q = _query.trim().toLowerCase();
    final list = all.where((s) {
      if (_onlyFav && !s.favorite) return false;
      if (q.isEmpty) return true;
      return '${s.displayName} ${s.mineral?.name ?? ''} ${s.place} ${s.notes}'
          .toLowerCase()
          .contains(q);
    }).toList();
    switch (_sort) {
      case _Sort.recent:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _Sort.found:
        list.sort((a, b) => b.foundAt.compareTo(a.foundAt));
      case _Sort.name:
        list.sort((a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
      case _Sort.number:
        list.sort(
            (a, b) => (a.mineral?.n ?? 9999).compareTo(b.mineral?.n ?? 9999));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final list = _apply(state.specimens);
    final df = DateFormat('d MMM y', 'es');

    return Scaffold(
      appBar: AppBar(
        title: const FamilyTitle('Colección', size: 22),
        actions: [
          IconButton(
            tooltip: 'Solo favoritas',
            onPressed: () => setState(() => _onlyFav = !_onlyFav),
            icon: Icon(
                _onlyFav ? Icons.star_rounded : Icons.star_outline_rounded,
                color: _onlyFav ? Colors.amber : null),
          ),
          PopupMenuButton<_Sort>(
            tooltip: 'Ordenar',
            icon: const Icon(Icons.sort_rounded),
            initialValue: _sort,
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: _Sort.recent, child: Text('Agregadas recientemente')),
              PopupMenuItem(
                  value: _Sort.found, child: Text('Fecha del hallazgo')),
              PopupMenuItem(value: _Sort.name, child: Text('Nombre')),
              PopupMenuItem(
                  value: _Sort.number, child: Text('Número de Pokédex')),
            ],
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar en mi colección…',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      state.specimens.isEmpty
                          ? 'Tu colección está vacía.\nToca "Capturar" para empezar.'
                          : 'No hay piedras que coincidan.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final s = list[i];
                    final m = s.mineral;
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    SpecimenDetailScreen(id: s.id))),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(children: [
                            SpecimenThumb(specimen: s, size: 76),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text(s.displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.w800)),
                                    ),
                                    if (s.favorite)
                                      const Icon(Icons.star_rounded,
                                          color: Colors.amber, size: 20),
                                  ]),
                                  const SizedBox(height: 4),
                                  if (m != null)
                                    KindChip(kind: m.kind, small: true)
                                  else
                                    Text('Sin identificar',
                                        style: TextStyle(
                                            color: cs.error,
                                            fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      df.format(s.foundAt),
                                      if (s.place.isNotEmpty) s.place,
                                    ].join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 13),
                                  ),
                                  if (s.origin != null)
                                    Text('Compartida por ${s.origin}',
                                        style: TextStyle(
                                            color: cs.primary, fontSize: 12.5)),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
