import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rockbosg/data/achievements.dart';
import 'package:rockbosg/data/catalog.dart';
import 'package:rockbosg/data/specimen.dart';
import 'package:rockbosg/services/updater.dart';
import 'package:rockbosg/version.dart';

void main() {
  test('catálogo con números e ids únicos y consecutivos', () {
    expect(catalog.map((m) => m.id).toSet().length, catalog.length);
    for (var i = 0; i < catalog.length; i++) {
      expect(catalog[i].n, i + 1, reason: catalog[i].name);
      expect(catalog[i].mohsMin <= catalog[i].mohsMax, true,
          reason: catalog[i].name);
    }
    for (final id in [...mohsScaleIds, ...copperIds]) {
      expect(mineralById(id), isNotNull, reason: id);
    }
  });

  test('stats y niveles', () {
    final s = Stats([
      Specimen(id: 'a', mineralId: 'pirita'),
      Specimen(id: 'b', mineralId: 'granito'),
      Specimen(id: 'c'),
    ]);
    expect(s.species.length, 2);
    expect(s.total, 3);
    expect(s.level >= 1, true);
    expect(achievements.firstWhere((a) => a.id == 'pyr').unlocked(s), true);
  });

  test('specimen ida y vuelta por mapa', () {
    final s = Specimen(
        id: 'x',
        mineralId: 'cuarzo',
        photos: ['1.jpg'],
        lat: -23.5,
        lng: -70.4);
    final back = Specimen.fromMap(s.toMap());
    expect(back.photos, ['1.jpg']);
    expect(back.lat, -23.5);
    expect(back.displayName, 'Cuarzo');
  });

  test('appVersion coincide con pubspec.yaml', () {
    final m = RegExp(r'^version:\s*([\d.]+)', multiLine: true)
        .firstMatch(File('pubspec.yaml').readAsStringSync());
    expect(m?.group(1), appVersion);
  });

  test('comparación de versiones', () {
    expect(Updater.compare('v1.0.1', '1.0.0') > 0, true);
    expect(Updater.compare('1.0.0', '1.0.0'), 0);
    expect(Updater.compare('1.2.0', '1.10.0') < 0, true);
    expect(Updater.compare('2.0', '1.9.9') > 0, true);
  });
}
