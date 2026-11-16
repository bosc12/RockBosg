import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../version.dart';
import '../widgets/common.dart';

/// Revisa si hay una versión nueva publicada en GitHub Releases.
///
/// Solo hace una consulta de lectura a la API pública de GitHub; no envía
/// datos de la colección ni del usuario.
class Updater {
  static const repo = 'bosc12/RockBosg';
  static const _lastCheckKey = 'updateLastCheck';

  /// Compara versiones "1.2.3". Devuelve > 0 si [a] es más nueva que [b].
  static int compare(String a, String b) {
    List<int> parts(String v) => v
        .replaceFirst(RegExp('^[vV]'), '')
        .split('+')
        .first
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final pa = parts(a), pb = parts(b);
    for (var i = 0; i < 3; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x - y;
    }
    return 0;
  }

  static Future<Release?> fetchLatest() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(
          Uri.parse('https://api.github.com/repos/$repo/releases/latest'));
      req.headers
        ..set(HttpHeaders.userAgentHeader, 'RockBosg-app')
        ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final body = await res.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final assets =
          (json['assets'] as List? ?? []).cast<Map<String, dynamic>>();
      final apk =
          assets.where((a) => (a['name'] as String? ?? '').endsWith('.apk'));
      return Release(
        version: (json['tag_name'] as String? ?? '')
            .replaceFirst(RegExp('^[vV]'), ''),
        notes: (json['body'] as String? ?? '').trim(),
        url: apk.isNotEmpty
            ? apk.first['browser_download_url'] as String
            : json['html_url'] as String,
      );
    } catch (_) {
      return null; // sin internet o GitHub no responde: no pasa nada
    } finally {
      client.close(force: true);
    }
  }

  /// [manual]: el usuario tocó "Buscar actualizaciones" (siempre responde).
  /// Automático: como máximo una vez al día y en silencio si no hay nada.
  static Future<void> check(BuildContext context, {bool manual = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!manual) {
      final last = prefs.getInt(_lastCheckKey) ?? 0;
      if (now - last < const Duration(hours: 20).inMilliseconds) return;
    }

    final rel = await fetchLatest();
    // Solo cuenta como revisado si GitHub respondió (sin internet se reintenta).
    if (rel != null) await prefs.setInt(_lastCheckKey, now);
    if (!context.mounted) return;
    if (rel == null || rel.version.isEmpty) {
      if (manual) showSnack(context, 'No se pudo revisar. ¿Hay internet?');
      return;
    }
    if (compare(rel.version, appVersion) <= 0) {
      if (manual) {
        showSnack(context, 'Ya tienes la última versión ($appVersion).');
      }
      return;
    }

    final notes =
        rel.notes.length > 600 ? '${rel.notes.substring(0, 600)}…' : rel.notes;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.system_update_rounded, size: 36),
        title: Text('Nueva versión ${rel.version}'),
        content: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
                'Tienes la $appVersion. Tu colección no se borra al actualizar.'),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(notes, style: Theme.of(ctx).textTheme.bodyMedium),
            ],
            const SizedBox(height: 12),
            const Text(
              'Se descargará el APK. Ábrelo y toca "Actualizar".',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Más tarde')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Descargar')),
        ],
      ),
    );
    if (go == true) {
      await launchUrl(Uri.parse(rel.url), mode: LaunchMode.externalApplication);
    }
  }
}

class Release {
  final String version;
  final String notes;
  final String url;
  const Release(
      {required this.version, required this.notes, required this.url});
}
