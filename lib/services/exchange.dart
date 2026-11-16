import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/specimen.dart';
import '../state.dart';
import '../widgets/common.dart';

/// Exportar / importar piedras como archivo .zip (para WhatsApp, correo, respaldo).
///
/// Formato: `rockbosg.json` + carpeta `photos/`. Sin servidores: todo queda
/// en los teléfonos.
class Exchange {
  static const _manifest = 'rockbosg.json';

  static String _safe(String s) => s
      .replaceAll(RegExp(r'[^A-Za-z0-9áéíóúÁÉÍÓÚñÑ_-]+'), '_')
      .replaceAll(RegExp('_+'), '_');

  /// Crea el archivo y abre el menú de compartir del teléfono.
  static Future<void> share(BuildContext context, List<Specimen> items,
      {bool single = false}) async {
    if (items.isEmpty) {
      showSnack(context, 'No hay piedras para exportar.');
      return;
    }
    final state = AppScope.read(context);
    try {
      final file = await _buildZip(state, items, single: single);
      final who = state.userName ?? 'alguien';
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/zip')],
        subject: single
            ? 'RockBosg: ${items.first.displayName}'
            : 'Colección RockBosg de $who',
        text: single
            ? '$who te comparte una piedra: ${items.first.displayName}. Ábrela en RockBosg → Ajustes → Importar.'
            : 'Colección de $who (${items.length} piedras). Ábrela en RockBosg → Ajustes → Importar.',
      );
    } catch (e) {
      if (context.mounted) showSnack(context, 'No se pudo exportar: $e');
    }
  }

  static Future<File> _buildZip(AppState state, List<Specimen> items,
      {required bool single}) async {
    final archive = Archive();
    final data = {
      'app': 'RockBosg',
      'format': 1,
      'owner': state.userName,
      'exportedAt': DateTime.now().toIso8601String(),
      'specimens': items.map((s) => s.toMap()).toList(),
    };
    archive.addFile(ArchiveFile.bytes(_manifest,
        utf8.encode(const JsonEncoder.withIndent(' ').convert(data))));
    for (final s in items) {
      for (final ph in s.photos) {
        final f = state.db.photoFile(ph);
        if (f.existsSync()) {
          archive.addFile(ArchiveFile.bytes('photos/$ph', f.readAsBytesSync()));
        }
      }
    }
    final bytes = ZipEncoder().encodeBytes(archive);

    final tmp = await getTemporaryDirectory();
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final name = single
        ? 'RockBosg_${_safe(items.first.displayName)}.zip'
        : 'RockBosg_Coleccion_${_safe(state.userName ?? 'Gomez')}_$date.zip';
    final out = File(p.join(tmp.path, name));
    await out.writeAsBytes(bytes, flush: true);
    return out;
  }

  /// Elige un archivo .zip y agrega sus piedras a la colección.
  static Future<void> import(BuildContext context) async {
    final state = AppScope.read(context);
    try {
      final res = await FilePicker.platform
          .pickFiles(type: FileType.any, withData: false);
      final path = res?.files.single.path;
      if (path == null) return;

      final archive = ZipDecoder().decodeBytes(await File(path).readAsBytes());
      final manifest = archive.findFile(_manifest);
      if (manifest == null) {
        throw const FormatException('El archivo no es de RockBosg.');
      }
      final data =
          jsonDecode(utf8.decode(manifest.content)) as Map<String, dynamic>;
      final owner = data['owner'] as String?;
      final fromOther = owner != null && owner != state.userName;

      final existing = {for (final s in state.specimens) s.id};
      var added = 0, skipped = 0;
      for (final raw
          in (data['specimens'] as List).cast<Map<String, dynamic>>()) {
        final s = Specimen.fromMap(raw);
        if (existing.contains(s.id)) {
          skipped++;
          continue;
        }
        for (final ph in s.photos) {
          final entry = archive.findFile('photos/$ph');
          final dest = state.db.photoFile(ph);
          if (entry != null && !dest.existsSync()) {
            await dest.writeAsBytes(entry.content, flush: true);
          }
        }
        s.photos = s.photos
            .where((ph) => state.db.photoFile(ph).existsSync())
            .toList();
        if (s.origin == null && fromOther) s.origin = owner;
        await state.db.upsert(s);
        added++;
      }
      await state.reload();
      if (!context.mounted) return;
      showSnack(
        context,
        added == 0
            ? 'No había piedras nuevas (ya las tenías).'
            : '¡Listo! ${added == 1 ? 'Se agregó 1 piedra' : 'Se agregaron $added piedras'}'
                '${fromOther ? ' de $owner' : ''}'
                '${skipped > 0 ? ' ($skipped ya estaban)' : ''}.',
      );
    } catch (e) {
      if (context.mounted) {
        showSnack(context,
            'No se pudo importar: ${e is FormatException ? e.message : e}');
      }
    }
  }
}
