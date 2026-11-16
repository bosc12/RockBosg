import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  AppMode? _mode;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ready = _name.text.trim().isNotEmpty && _mode != null;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          children: [
            const Center(child: AppLogo(size: 120)),
            const SizedBox(height: 20),
            const Center(child: FamilyTitle('Colección', size: 30)),
            const SizedBox(height: 6),
            Center(
              child: Text('Tu Pokédex de rocas y minerales',
                  style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant)),
            ),
            const SizedBox(height: 32),
            const Text('¿Cómo te llamas?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(hintText: 'Tu nombre'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 28),
            const Text('Elige tu modo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Lo puedes cambiar cuando quieras en Ajustes.',
                style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            ModeCard(
              selected: _mode == AppMode.explorer,
              icon: Icons.explore_rounded,
              color: Brand.kindColor('ignea'),
              title: 'Modo Explorador',
              subtitle: 'Niveles, insignias y datos curiosos de cada piedra.',
              onTap: () => setState(() => _mode = AppMode.explorer),
            ),
            const SizedBox(height: 12),
            ModeCard(
              selected: _mode == AppMode.geologist,
              icon: Icons.science_rounded,
              color: Brand.cyanDeep,
              title: 'Modo Geólogo',
              subtitle:
                  'Fichas técnicas completas, fórmulas y letra más grande.',
              onTap: () => setState(() => _mode = AppMode.geologist),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: ready
                  ? () => AppScope.read(context).setProfile(_name.text, _mode!)
                  : null,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Comenzar'),
            ),
            const SizedBox(height: 28),
            const Center(child: CompanyLogo(width: 110)),
          ],
        ),
      ),
    );
  }
}

class ModeCard extends StatelessWidget {
  const ModeCard({
    super.key,
    required this.selected,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? color.withOpacity(0.12) : cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: selected ? color : cs.outlineVariant,
                width: selected ? 2 : 1),
          ),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ]),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: color),
          ]),
        ),
      ),
    );
  }
}
