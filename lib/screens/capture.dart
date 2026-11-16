import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../data/achievements.dart';
import '../data/catalog.dart';
import '../data/db.dart';
import '../data/specimen.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'pokedex.dart';

const _uuid = Uuid();

/// Pregunta cámara o galería, guarda la foto y abre el formulario.
Future<void> startCapture(BuildContext context, {Mineral? preset}) async {
  final file = await pickPhoto(context);
  if (file == null || !context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(
        builder: (_) => SpecimenEditScreen(initialPhoto: file, preset: preset)),
  );
}

/// Devuelve el nombre del archivo guardado en la carpeta de fotos.
Future<String?> pickPhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Agregar foto',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, ImageSource.camera),
                icon: const Icon(Icons.photo_camera_rounded),
                label: const Text('Tomar foto'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Elegir de la galería'),
              ),
            ]),
      ),
    ),
  );
  if (source == null || !context.mounted) return null;

  try {
    final picked = await ImagePicker().pickImage(
        source: source, maxWidth: 2200, maxHeight: 2200, imageQuality: 85);
    if (picked == null || !context.mounted) return null;
    final name = '${_uuid.v4()}.jpg';
    await File(picked.path)
        .copy(AppScope.read(context).db.photoFile(name).path);
    return name;
  } catch (e) {
    if (context.mounted) showSnack(context, 'No se pudo obtener la foto: $e');
    return null;
  }
}

/// Formulario para crear o editar una piedra.
class SpecimenEditScreen extends StatefulWidget {
  const SpecimenEditScreen(
      {super.key, this.existing, this.initialPhoto, this.preset});

  final Specimen? existing;
  final String? initialPhoto;
  final Mineral? preset;

  @override
  State<SpecimenEditScreen> createState() => _SpecimenEditScreenState();
}

class _SpecimenEditScreenState extends State<SpecimenEditScreen> {
  late final Specimen _s;
  late final List<String> _photos;
  final List<String> _added = [];
  final List<String> _removed = [];
  bool _saved = false;
  bool _locating = false;
  bool _showScience = false;
  late LocalDb _db;

  late final _name = TextEditingController(text: _s.name);
  late final _place = TextEditingController(text: _s.place);
  late final _mohs = TextEditingController(text: _s.mohs);
  late final _color = TextEditingController(text: _s.color);
  late final _luster = TextEditingController(text: _s.luster);
  late final _streak = TextEditingController(text: _s.streak);
  late final _weight = TextEditingController(text: _s.weight);
  late final _size = TextEditingController(text: _s.size);
  late final _notes = TextEditingController(text: _s.notes);

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _s = e != null
        ? Specimen.fromMap(
            e.toMap()) // copia para no tocar el original hasta guardar
        : Specimen(id: _uuid.v4(), mineralId: widget.preset?.id);
    _photos = [..._s.photos];
    if (widget.initialPhoto != null) {
      _photos.add(widget.initialPhoto!);
      _added.add(widget.initialPhoto!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.read(context);
    _db = state.db;
    _showScience = _showScience || state.isGeologist;
  }

  @override
  void dispose() {
    // Si se cancela, se borran las fotos nuevas que no se guardaron.
    if (!_saved) {
      for (final f in _added) {
        final file = _db.photoFile(f);
        if (file.existsSync()) file.deleteSync();
      }
    }
    for (final c in [
      _name,
      _place,
      _mohs,
      _color,
      _luster,
      _streak,
      _weight,
      _size,
      _notes
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final f = await pickPhoto(context);
    if (f != null) {
      setState(() {
        _photos.add(f);
        _added.add(f);
      });
    }
  }

  void _removePhoto(String f) {
    setState(() {
      _photos.remove(f);
      if (_added.remove(f)) {
        final file = _db.photoFile(f);
        if (file.existsSync()) file.deleteSync();
      } else {
        _removed.add(f);
      }
    });
  }

  Future<void> _pickMineral() async {
    final m = await Navigator.push<Mineral>(context,
        MaterialPageRoute(builder: (_) => const MineralPickerScreen()));
    if (m != null) setState(() => _s.mineralId = m.id);
  }

  void _fillFromCatalog() {
    final m = _s.mineral;
    if (m == null) return;
    setState(() {
      if (_mohs.text.isEmpty) _mohs.text = m.mohsText;
      if (_color.text.isEmpty) _color.text = m.colors;
      if (_luster.text.isEmpty) _luster.text = m.luster;
      if (_streak.text.isEmpty && m.streak != null) _streak.text = m.streak!;
    });
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          showSnack(context, 'Activa la ubicación (GPS) del teléfono.');
        }
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) showSnack(context, 'Sin permiso de ubicación.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 25)),
      );
      setState(() {
        _s.lat = pos.latitude;
        _s.lng = pos.longitude;
      });
    } catch (e) {
      if (mounted) {
        showSnack(
            context, 'No se pudo obtener la ubicación. Intenta al aire libre.');
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _s.foundAt,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es'),
    );
    if (d != null) setState(() => _s.foundAt = d);
  }

  Future<void> _save() async {
    final state = AppScope.read(context);
    final before = state.stats;
    final wasNewSpecies =
        _s.mineralId != null && !before.species.contains(_s.mineralId);
    final unlockedBefore =
        achievements.where((a) => a.unlocked(before)).map((a) => a.id).toSet();

    _s
      ..name = _name.text.trim()
      ..place = _place.text.trim()
      ..mohs = _mohs.text.trim()
      ..color = _color.text.trim()
      ..luster = _luster.text.trim()
      ..streak = _streak.text.trim()
      ..weight = _weight.text.trim()
      ..size = _size.text.trim()
      ..notes = _notes.text.trim()
      ..photos = [..._photos];

    await state.save(_s);
    for (final f in _removed) {
      final file = state.db.photoFile(f);
      if (file.existsSync()) file.deleteSync();
    }
    _saved = true;
    if (!mounted) return;

    final newBadges = achievements
        .where((a) => a.unlocked(state.stats) && !unlockedBefore.contains(a.id))
        .toList();
    final nav = Navigator.of(context);
    if (wasNewSpecies || newBadges.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (_) => _CelebrationDialog(
          mineral: wasNewSpecies ? _s.mineral : null,
          badges: newBadges,
          explorer: !state.isGeologist,
        ),
      );
    } else {
      showSnack(context,
          _isNew ? 'Piedra guardada en tu colección' : 'Cambios guardados');
    }
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final db = AppScope.read(context).db;
    final m = _s.mineral;
    final df = DateFormat("d 'de' MMMM 'de' y", 'es');

    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'Nueva piedra' : 'Editar piedra')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        children: [
          // Fotos
          SizedBox(
            height: 132,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final f in _photos)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(db.photoFile(f),
                            width: 132,
                            height: 132,
                            fit: BoxFit.cover,
                            cacheWidth: 400),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton.filled(
                          style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              minimumSize: const Size(32, 32),
                              padding: EdgeInsets.zero),
                          iconSize: 18,
                          tooltip: 'Quitar foto',
                          onPressed: () => _removePhoto(f),
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white),
                        ),
                      ),
                    ]),
                  ),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _addPhoto,
                  child: Container(
                    width: 132,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.outlineVariant, width: 1.5),
                    ),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded,
                              color: cs.primary, size: 30),
                          const SizedBox(height: 6),
                          const Text('Agregar foto',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ]),
                  ),
                ),
              ],
            ),
          ),

          const SectionTitle('¿Qué es?'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _pickMineral,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  if (m != null)
                    MineralAvatar(mineral: m, size: 50)
                  else
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                          color: cs.surfaceContainer,
                          borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.help_outline_rounded),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              m == null
                                  ? 'Elegir del catálogo'
                                  : '${m.number} · ${m.name}',
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w800)),
                          Text(
                            m == null
                                ? 'Si no sabes aún, puedes dejarla sin identificar'
                                : kindLabels[m.kind]!,
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ]),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ]),
              ),
            ),
          ),
          if (m != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: () => setState(() => _s.mineralId = null),
                  child: const Text('Quitar identificación')),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Nombre o apodo (opcional)',
              hintText: m == null
                  ? 'Ej: Piedra brillante del río'
                  : 'Ej: ${m.name} de la mina',
            ),
          ),

          const SectionTitle('¿Dónde y cuándo?'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(Icons.event_rounded),
              title: Text(df.format(_s.foundAt),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Fecha del hallazgo'),
              trailing: const Icon(Icons.edit_calendar_rounded),
              onTap: _pickDate,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _place,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Lugar',
              hintText: 'Ej: Quebrada cerca de la mina, playa…',
              prefixIcon: Icon(Icons.place_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _locating ? null : _locate,
                icon: _locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location_rounded),
                label: Text(_s.hasLocation
                    ? '${_s.lat!.toStringAsFixed(5)}, ${_s.lng!.toStringAsFixed(5)}'
                    : 'Guardar ubicación GPS'),
              ),
            ),
            if (_s.hasLocation)
              IconButton(
                tooltip: 'Quitar ubicación',
                onPressed: () => setState(() {
                  _s.lat = null;
                  _s.lng = null;
                }),
                icon: const Icon(Icons.close_rounded),
              ),
          ]),

          SectionTitle(
            'Datos científicos',
            trailing: TextButton(
              onPressed: () => setState(() => _showScience = !_showScience),
              child: Text(_showScience ? 'Ocultar' : 'Mostrar'),
            ),
          ),
          if (_showScience) ...[
            if (m != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton.icon(
                  onPressed: _fillFromCatalog,
                  icon: const Icon(Icons.auto_fix_high_rounded),
                  label: const Text('Rellenar con datos del catálogo'),
                ),
              ),
            Row(children: [
              Expanded(
                child: TextField(
                    controller: _mohs,
                    decoration:
                        const InputDecoration(labelText: 'Dureza (Mohs)')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                    controller: _streak,
                    decoration: const InputDecoration(labelText: 'Raya')),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextField(
                    controller: _color,
                    decoration: const InputDecoration(labelText: 'Color')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                    controller: _luster,
                    decoration: InputDecoration(
                        labelText: m?.isRock == true ? 'Textura' : 'Brillo')),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextField(
                    controller: _weight,
                    decoration: const InputDecoration(
                        labelText: 'Peso', hintText: 'Ej: 120 g')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                    controller: _size,
                    decoration: const InputDecoration(
                        labelText: 'Tamaño', hintText: 'Ej: 5 × 3 cm')),
              ),
            ]),
          ],

          const SectionTitle('Notas'),
          TextField(
            controller: _notes,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                hintText:
                    'Lo que quieras recordar: quién la encontró, cómo, asociaciones…'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded),
            label: Text(_isNew ? 'Guardar en mi colección' : 'Guardar cambios'),
          ),
        ),
      ),
    );
  }
}

class _CelebrationDialog extends StatelessWidget {
  const _CelebrationDialog(
      {this.mineral, required this.badges, required this.explorer});

  final Mineral? mineral;
  final List<Achievement> badges;
  final bool explorer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final m = mineral;
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        if (m != null) ...[
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: MineralAvatar(mineral: m, size: 96),
          ),
          const SizedBox(height: 16),
          Text('¡Nueva especie descubierta!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
          const SizedBox(height: 4),
          Text('${m.number} · ${m.name}',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          RarityStars(rarity: m.rarity, size: 20),
          if (explorer) ...[
            const SizedBox(height: 10),
            Text('+${25 + 15 * (m.rarity - 1) + 10} XP',
                style: const TextStyle(
                    color: Brand.gold,
                    fontWeight: FontWeight.w900,
                    fontSize: 18)),
          ],
        ],
        if (badges.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
              badges.length == 1
                  ? '🏅 Insignia desbloqueada'
                  : '🏅 Insignias desbloqueadas',
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          for (final b in badges)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(b.icon, color: Brand.gold),
              title: Text(b.title,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(b.description),
            ),
        ],
      ]),
      actions: [
        FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('¡Genial!')),
      ],
    );
  }
}
