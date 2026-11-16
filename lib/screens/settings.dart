import 'package:flutter/material.dart';

import '../services/exchange.dart';
import '../services/updater.dart';
import '../version.dart';
import '../state.dart';
import '../widgets/common.dart';
import 'onboarding.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final dark = state.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const SectionTitle('Perfil'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(Icons.person_rounded),
              title: Text(state.userName ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Toca para cambiar tu nombre'),
              trailing: const Icon(Icons.edit_rounded),
              onTap: () => _editName(context, state),
            ),
          ),
          const SizedBox(height: 10),
          ModeCard(
            selected: state.mode == AppMode.explorer,
            icon: Icons.explore_rounded,
            color: const Color(0xFFE0603A),
            title: 'Modo Explorador',
            subtitle: 'Niveles, insignias y datos curiosos.',
            onTap: () => state.setMode(AppMode.explorer),
          ),
          const SizedBox(height: 10),
          ModeCard(
            selected: state.mode == AppMode.geologist,
            icon: Icons.science_rounded,
            color: cs.primary,
            title: 'Modo Geólogo',
            subtitle: 'Fichas técnicas completas y fórmulas.',
            onTap: () => state.setMode(AppMode.geologist),
          ),
          const SectionTitle('Pantalla'),
          Card(
            child: Column(children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_rounded),
                title: const Text('Modo oscuro',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('El claro se lee mejor al sol'),
                value: dark,
                onChanged: (v) =>
                    state.setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.text_increase_rounded),
                title: const Text('Letra grande',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                value: state.largeText,
                onChanged: state.setLargeText,
              ),
            ]),
          ),
          const SectionTitle('Compartir y respaldo'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.upload_file_rounded),
                title: const Text('Exportar toda mi colección',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    '${state.specimens.length} ${state.specimens.length == 1 ? 'piedra' : 'piedras'} con sus fotos en un archivo .zip. '
                    'Mándalo por WhatsApp o guárdalo como respaldo.'),
                onTap: () => Exchange.share(context, state.specimens),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: const Text('Importar piedras',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text(
                    'Abre un archivo .zip de RockBosg que te hayan enviado. No se duplican las que ya tienes.'),
                onTap: () => Exchange.import(context),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tus piedras y fotos se guardan solo en este teléfono. Si desinstalas la app se pierden, '
            'así que exporta un respaldo de vez en cuando.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          const SectionTitle('Actualizaciones'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(Icons.system_update_rounded),
              title: const Text('Buscar actualizaciones',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Versión instalada: $appVersion'),
              onTap: () => Updater.check(context, manual: true),
            ),
          ),
          const SectionTitle('Acerca de'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const AppLogo(size: 88),
                const SizedBox(height: 12),
                const FamilyTitle('RockBosg · Familia', size: 20),
                const SizedBox(height: 6),
                Text(
                  'Hecha con cariño para el abuelo geólogo y el explorador más joven de la familia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                const CompanyLogo(width: 150),
                const SizedBox(height: 8),
                Text('Versión $appVersion',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, AppState state) async {
    final c = TextEditingController(text: state.userName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tu nombre'),
        content: TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await state.setProfile(name, state.mode ?? AppMode.explorer);
    }
  }
}
