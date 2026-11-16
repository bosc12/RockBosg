import 'package:flutter/material.dart';

import 'catalog.dart';
import 'specimen.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int goal;
  final int Function(Stats s) progress;

  const Achievement(this.id, this.title, this.description, this.icon, this.goal,
      this.progress);

  bool unlocked(Stats s) => progress(s) >= goal;
}

/// Estadísticas calculadas a partir de la colección.
class Stats {
  final List<Specimen> specimens;
  late final Set<String> species;
  late final Map<String, int> byKind;
  late final int photos;
  late final int withGps;
  late final int scientific;
  late final int imported;
  late final int rareSpecies;

  Stats(this.specimens) {
    species = {
      for (final s in specimens)
        if (s.mineralId != null) s.mineralId!
    };
    byKind = {'mineral': 0, 'ignea': 0, 'sedimentaria': 0, 'metamorfica': 0};
    for (final id in species) {
      final m = mineralById(id);
      if (m != null) byKind[m.kind] = byKind[m.kind]! + 1;
    }
    photos = specimens.fold(0, (a, s) => a + s.photos.length);
    withGps = specimens.where((s) => s.hasLocation).length;
    scientific = specimens
        .where((s) => s.mohs.trim().isNotEmpty && s.streak.trim().isNotEmpty)
        .length;
    imported = specimens.where((s) => s.origin != null).length;
    rareSpecies =
        species.where((id) => (mineralById(id)?.rarity ?? 0) == 3).length;
  }

  int get total => specimens.length;
  int get mohsFound => mohsScaleIds.where(species.contains).length;
  int get copperFound => copperIds.where(species.contains).length;
  int get rockTypes => ['ignea', 'sedimentaria', 'metamorfica']
      .where((k) => byKind[k]! > 0)
      .length;
  double get completion => species.length / catalog.length;

  /// Puntos de experiencia.
  int get xp {
    var x = total * 10;
    for (final id in species) {
      x += 25 + 15 * ((mineralById(id)?.rarity ?? 1) - 1);
    }
    x += achievements.where((a) => a.unlocked(this)).length * 50;
    return x;
  }

  /// Nivel: cada nivel necesita un poco más que el anterior.
  int get level => _levelFor(xp);
  int get xpForThisLevel => _xpFor(level);
  int get xpForNextLevel => _xpFor(level + 1);

  static int _xpFor(int level) =>
      50 * (level - 1) * level; // 0, 100, 300, 600...
  static int _levelFor(int xp) {
    var l = 1;
    while (_xpFor(l + 1) <= xp) {
      l++;
    }
    return l;
  }

  String get rank {
    final l = level;
    if (l >= 20) return 'Maestro Gómez';
    if (l >= 15) return 'Geólogo junior';
    if (l >= 10) return 'Cazador de minerales';
    if (l >= 6) return 'Explorador';
    if (l >= 3) return 'Buscador de piedras';
    return 'Aprendiz de roca';
  }
}

final achievements = <Achievement>[
  Achievement('first', 'Primera captura', 'Registra tu primera piedra',
      Icons.flag_rounded, 1, (s) => s.total),
  Achievement('c10', 'Coleccionista', 'Registra 10 piedras',
      Icons.inventory_2_rounded, 10, (s) => s.total),
  Achievement('c25', 'Gran coleccionista', 'Registra 25 piedras',
      Icons.collections_rounded, 25, (s) => s.total),
  Achievement('c50', 'Museo Gómez', 'Registra 50 piedras', Icons.museum_rounded,
      50, (s) => s.total),
  Achievement(
      'sp10',
      'Explorador de especies',
      'Descubre 10 especies distintas',
      Icons.travel_explore_rounded,
      10,
      (s) => s.species.length),
  Achievement('sp25', 'Naturalista', 'Descubre 25 especies distintas',
      Icons.auto_stories_rounded, 25, (s) => s.species.length),
  Achievement(
      'half',
      'Medio catálogo',
      'Descubre la mitad de la Pokédex',
      Icons.donut_large_rounded,
      (catalog.length / 2).ceil(),
      (s) => s.species.length),
  Achievement(
      'trio',
      'Ciclo de las rocas',
      'Una roca ígnea, una sedimentaria y una metamórfica',
      Icons.autorenew_rounded,
      3,
      (s) => s.rockTypes),
  Achievement('ign', 'Corazón volcánico', 'Descubre 3 rocas ígneas',
      Icons.volcano_rounded, 3, (s) => s.byKind['ignea']!),
  Achievement('sed', 'Capas del tiempo', 'Descubre 3 rocas sedimentarias',
      Icons.layers_rounded, 3, (s) => s.byKind['sedimentaria']!),
  Achievement('met', 'Bajo presión', 'Descubre 3 rocas metamórficas',
      Icons.compress_rounded, 3, (s) => s.byKind['metamorfica']!),
  Achievement('min10', 'Mineralogista', 'Descubre 10 minerales',
      Icons.diamond_rounded, 10, (s) => s.byKind['mineral']!),
  Achievement(
      'mohs',
      'Escala de Mohs',
      'Consigue los 10 minerales de la escala de Mohs',
      Icons.straighten_rounded,
      10,
      (s) => s.mohsFound),
  Achievement('cu', 'Minero del cobre', 'Descubre 3 minerales de cobre',
      Icons.construction_rounded, 3, (s) => s.copperFound),
  Achievement(
      'pyr',
      'Oro de los tontos',
      'Encuentra una pirita',
      Icons.auto_awesome_rounded,
      1,
      (s) => s.species.contains('pirita') ? 1 : 0),
  Achievement('rare', 'Tesoro raro', 'Descubre una especie rara',
      Icons.workspace_premium_rounded, 1, (s) => s.rareSpecies),
  Achievement('gps', 'Cartógrafo', 'Guarda la ubicación de 5 piedras',
      Icons.map_rounded, 5, (s) => s.withGps),
  Achievement('pics', 'Fotógrafo de campo', 'Toma 20 fotos',
      Icons.photo_camera_rounded, 20, (s) => s.photos),
  Achievement('sci', 'Científico', 'Registra dureza y raya en 5 piedras',
      Icons.science_rounded, 5, (s) => s.scientific),
  Achievement(
      'trade',
      'Intercambio',
      'Importa una piedra compartida por otra persona',
      Icons.swap_horiz_rounded,
      1,
      (s) => s.imported),
];
