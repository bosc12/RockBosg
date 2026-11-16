import 'dart:convert';

import 'catalog.dart';

/// Una piedra real de la colección (lo que el usuario "capturó").
class Specimen {
  final String id;
  String? mineralId; // null = aún sin identificar
  String name;
  List<String> photos; // nombres de archivo dentro de la carpeta de fotos
  DateTime foundAt;
  String place;
  double? lat;
  double? lng;
  String mohs;
  String color;
  String luster;
  String streak;
  String weight;
  String size;
  String notes;
  bool favorite;
  String? origin; // nombre de quien la compartió (si fue importada)
  final DateTime createdAt;

  Specimen({
    required this.id,
    this.mineralId,
    this.name = '',
    List<String>? photos,
    DateTime? foundAt,
    this.place = '',
    this.lat,
    this.lng,
    this.mohs = '',
    this.color = '',
    this.luster = '',
    this.streak = '',
    this.weight = '',
    this.size = '',
    this.notes = '',
    this.favorite = false,
    this.origin,
    DateTime? createdAt,
  })  : photos = photos ?? [],
        foundAt = foundAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Mineral? get mineral => mineralById(mineralId);

  String get displayName {
    if (name.trim().isNotEmpty) return name.trim();
    return mineral?.name ?? 'Piedra sin identificar';
  }

  bool get hasLocation => lat != null && lng != null;

  Map<String, Object?> toMap() => {
        'id': id,
        'mineralId': mineralId,
        'name': name,
        'photos': jsonEncode(photos),
        'foundAt': foundAt.millisecondsSinceEpoch,
        'place': place,
        'lat': lat,
        'lng': lng,
        'mohs': mohs,
        'color': color,
        'luster': luster,
        'streak': streak,
        'weight': weight,
        'size': size,
        'notes': notes,
        'favorite': favorite ? 1 : 0,
        'origin': origin,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Specimen.fromMap(Map<String, Object?> m) => Specimen(
        id: m['id'] as String,
        mineralId: m['mineralId'] as String?,
        name: (m['name'] as String?) ?? '',
        photos: (jsonDecode((m['photos'] as String?) ?? '[]') as List)
            .cast<String>(),
        foundAt:
            DateTime.fromMillisecondsSinceEpoch((m['foundAt'] as num).toInt()),
        place: (m['place'] as String?) ?? '',
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        mohs: (m['mohs'] as String?) ?? '',
        color: (m['color'] as String?) ?? '',
        luster: (m['luster'] as String?) ?? '',
        streak: (m['streak'] as String?) ?? '',
        weight: (m['weight'] as String?) ?? '',
        size: (m['size'] as String?) ?? '',
        notes: (m['notes'] as String?) ?? '',
        favorite: (m['favorite'] as num?) == 1,
        origin: m['origin'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (m['createdAt'] as num).toInt()),
      );
}
