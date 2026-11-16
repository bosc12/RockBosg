import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'mineral_detail.dart';

class PokedexScreen extends StatelessWidget {
  const PokedexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context).stats;
    return Scaffold(
      appBar: AppBar(
        title: const FamilyTitle('Pokédex', size: 22),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('${st.species.length}/${catalog.length}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
      body: CatalogBrowser(
        onSelect: (m) => Navigator.push(context,
            MaterialPageRoute(builder: (_) => MineralDetailScreen(mineral: m))),
      ),
    );
  }
}

/// Pantalla para elegir qué es una piedra (al capturar o editar).
class MineralPickerScreen extends StatelessWidget {
  const MineralPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('¿Qué piedra es?')),
      body: CatalogBrowser(
        picking: true,
        onSelect: (m) => Navigator.pop(context, m),
      ),
    );
  }
}

/// Lista filtrable del catálogo (Pokédex y selector).
class CatalogBrowser extends StatefulWidget {
  const CatalogBrowser(
      {super.key, required this.onSelect, this.picking = false});

  final void Function(Mineral) onSelect;
  final bool picking;

  @override
  State<CatalogBrowser> createState() => _CatalogBrowserState();
}

class _CatalogBrowserState extends State<CatalogBrowser> {
  String _query = '';
  String? _kind;
  bool _onlyFound = false;
  bool _showId = false;
  RangeValues _mohs = const RangeValues(1, 10);
  String? _luster; // 'metal' | 'nometal'
  String? _streak; // texto que debe aparecer en la raya

  static const _streakOptions = [
    'Blanca',
    'Negra',
    'Gris',
    'Roj',
    'Marrón',
    'Amarill',
    'Verde',
    'Azul',
    'Naranja',
  ];

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');

  List<Mineral> _filtered(Set<String> found) {
    final q = _norm(_query.trim());
    return catalog.where((m) {
      if (_kind != null && m.kind != _kind) return false;
      if (_onlyFound && !found.contains(m.id)) return false;
      if (q.isNotEmpty &&
          !_norm('${m.name} ${m.group} ${m.formula ?? ''} ${m.colors} ${m.number}')
              .contains(q)) {
        return false;
      }
      if (m.mohsMax < _mohs.start || m.mohsMin > _mohs.end) return false;
      if (_luster != null) {
        final metallic = _norm(m.luster).contains('metalico') &&
            !_norm(m.luster).startsWith('submetalico');
        if (_luster == 'metal' && !metallic) return false;
        if (_luster == 'nometal' && metallic) return false;
      }
      if (_streak != null && !_norm(m.streak ?? '').contains(_norm(_streak!))) {
        return false;
      }
      return true;
    }).toList();
  }

  bool get _idFiltersActive =>
      _mohs.start > 1 || _mohs.end < 10 || _luster != null || _streak != null;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final found = state.stats.species;
    final cs = Theme.of(context).colorScheme;
    final list = _filtered(found);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Buscar por nombre, color, fórmula…',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              tooltip: 'Filtros de identificación',
              icon: Badge(
                isLabelVisible: _idFiltersActive,
                smallSize: 8,
                child: Icon(Icons.tune_rounded,
                    color: _showId ? cs.primary : null),
              ),
              onPressed: () => setState(() => _showId = !_showId),
            ),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
      ),
      SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _chip('Todos', _kind == null, () => setState(() => _kind = null)),
            for (final k in kindShort.keys)
              _chip(kindShort[k]!, _kind == k, () => setState(() => _kind = k),
                  color: Brand.kindColor(k)),
            if (!widget.picking)
              _chip('Descubiertas', _onlyFound,
                  () => setState(() => _onlyFound = !_onlyFound),
                  icon: Icons.check_circle_rounded),
          ],
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: _showId ? _idPanel(cs) : const SizedBox(width: double.infinity),
      ),
      if (widget.picking)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text(
            'Toca la especie que corresponde. Usa los filtros (⚙) para identificar por dureza, brillo y raya.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
        ),
      Expanded(
        child: list.isEmpty
            ? Center(
                child: Text('No hay coincidencias',
                    style: TextStyle(color: cs.onSurfaceVariant)))
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 140,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.78,
                ),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final m = list[i];
                  final got = found.contains(m.id);
                  return _MineralCard(
                    mineral: m,
                    discovered: got,
                    count: got ? state.specimensOf(m.id).length : 0,
                    onTap: () => widget.onSelect(m),
                  );
                },
              ),
      ),
    ]);
  }

  Widget _idPanel(ColorScheme cs) {
    String f(double v) => v.round().toString();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Dureza (Mohs)',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const Spacer(),
          Text('${f(_mohs.start)} – ${f(_mohs.end)}',
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
        ]),
        RangeSlider(
          values: _mohs,
          min: 1,
          max: 10,
          divisions: 9,
          labels: RangeLabels(f(_mohs.start), f(_mohs.end)),
          onChanged: (v) => setState(() => _mohs = v),
        ),
        Text(
            'Uña ≈ 2,5 · moneda de cobre ≈ 3,5 · navaja/vidrio ≈ 5,5 · lima de acero ≈ 6,5',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 10),
        const Text('Brillo', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [
          ChoiceChip(
              label: const Text('Metálico'),
              selected: _luster == 'metal',
              onSelected: (v) => setState(() => _luster = v ? 'metal' : null)),
          ChoiceChip(
              label: const Text('No metálico'),
              selected: _luster == 'nometal',
              onSelected: (v) =>
                  setState(() => _luster = v ? 'nometal' : null)),
        ]),
        const SizedBox(height: 10),
        const Text('Color de la raya',
            style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 6, children: [
          for (final s in _streakOptions)
            ChoiceChip(
              label: Text(switch (s) {
                'Roj' => 'Roja',
                'Amarill' => 'Amarilla',
                _ => s,
              }),
              selected: _streak == s,
              onSelected: (v) => setState(() => _streak = v ? s : null),
            ),
        ]),
        if (_idFiltersActive)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() {
                _mohs = const RangeValues(1, 10);
                _luster = null;
                _streak = null;
              }),
              icon: const Icon(Icons.clear_rounded),
              label: const Text('Limpiar filtros'),
            ),
          ),
      ]),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap,
      {Color? color, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        avatar: icon != null ? Icon(icon, size: 16) : null,
        selected: selected,
        selectedColor:
            (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.2),
        showCheckmark: false,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _MineralCard extends StatelessWidget {
  const _MineralCard({
    required this.mineral,
    required this.discovered,
    required this.count,
    required this.onTap,
  });

  final Mineral mineral;
  final bool discovered;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Column(children: [
            Row(children: [
              Text(mineral.number,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurfaceVariant)),
              const Spacer(),
              if (discovered)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('×$count',
                      style: TextStyle(
                          color: cs.onPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ),
            ]),
            const Spacer(),
            Opacity(
              opacity: discovered ? 1 : 0.55,
              child: MineralAvatar(
                  mineral: mineral, size: 54, locked: !discovered),
            ),
            const Spacer(),
            Text(
              mineral.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.15,
                fontWeight: FontWeight.w700,
                color: discovered ? cs.onSurface : cs.onSurfaceVariant,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
