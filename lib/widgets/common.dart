import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/specimen.dart';
import '../state.dart';
import '../theme.dart';

/// Ícono de gema con el color típico del mineral.
class MineralAvatar extends StatelessWidget {
  const MineralAvatar(
      {super.key, required this.mineral, this.size = 56, this.locked = false});

  final Mineral mineral;
  final double size;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final base = locked ? Colors.grey : Brand.forMineral(mineral);
    final light = Color.lerp(base, Colors.white, 0.35)!;
    final dark = Color.lerp(base, Colors.black, 0.35)!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: locked
              ? [Colors.grey.shade400, Colors.grey.shade600]
              : [light, base, dark],
        ),
      ),
      child: Icon(
        locked ? Icons.lock_rounded : Brand.kindIcon(mineral.kind),
        size: size * 0.5,
        color: Colors.white.withOpacity(locked ? 0.85 : 0.9),
      ),
    );
  }
}

/// Miniatura de una piedra: su primera foto o el ícono del mineral.
class SpecimenThumb extends StatelessWidget {
  const SpecimenThumb(
      {super.key, required this.specimen, this.size = 64, this.radius = 14});

  final Specimen specimen;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    Widget child;
    if (specimen.photos.isNotEmpty) {
      child = Image.file(
        state.db.photoFile(specimen.photos.first),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 3).round(),
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    } else {
      child = _fallback(context);
    }
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
  }

  Widget _fallback(BuildContext context) {
    final m = specimen.mineral;
    if (m != null) return MineralAvatar(mineral: m, size: size);
    return Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Icon(Icons.help_outline_rounded, size: size * 0.45),
    );
  }
}

class KindChip extends StatelessWidget {
  const KindChip({super.key, required this.kind, this.small = false});

  final String kind;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = Brand.kindColor(kind);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 10, vertical: small ? 3 : 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Brand.kindIcon(kind), size: small ? 13 : 15, color: c),
        const SizedBox(width: 4),
        Text(kindLabels[kind]!,
            style: TextStyle(
                fontSize: small ? 11.5 : 13,
                fontWeight: FontWeight.w700,
                color: c)),
      ]),
    );
  }
}

class RarityStars extends StatelessWidget {
  const RarityStars({super.key, required this.rarity, this.size = 16});

  final int rarity;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Icon(
          i < rarity ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color:
              i < rarity ? Brand.gold : Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

/// Logo de la app; si aún no está el archivo, muestra un ícono.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/logo_rockbosg.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: Brand.slate,
          child:
              Icon(Icons.diamond_rounded, color: Brand.cyan, size: size * 0.55),
        ),
      ),
    );
  }
}

class CompanyLogo extends StatelessWidget {
  const CompanyLogo({super.key, this.width = 160});

  final double width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'assets/logo_bosg.png',
        width: width,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: Colors.black,
          alignment: Alignment.center,
          child: const Text('BOSG',
              style: TextStyle(
                  color: Brand.cyan,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6)),
        ),
      ),
    );
  }
}

/// Título con el apellido de la familia destacado: "Colección **Gómez**".
class FamilyTitle extends StatelessWidget {
  const FamilyTitle(this.prefix, {super.key, this.size = 24});

  final String prefix;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: '$prefix '),
        TextSpan(text: 'Gómez', style: TextStyle(color: cs.primary)),
      ]),
      style: TextStyle(
          fontSize: size, fontWeight: FontWeight.w800, letterSpacing: -0.4),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Row(children: [
        Expanded(
          child: Text(text,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// Fila "propiedad: valor" para fichas técnicas.
class PropRow extends StatelessWidget {
  const PropRow(this.label, this.value, {super.key, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (icon != null) ...[
          Icon(icon, size: 19, color: cs.primary),
          const SizedBox(width: 10),
        ],
        SizedBox(
          width: 110,
          child: Text(label,
              style: TextStyle(
                  color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
        ),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
}
