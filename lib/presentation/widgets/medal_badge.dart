import 'package:flutter/material.dart';
import '../../core/theme/app_tokens.dart';

/// Exibe a medalha/posição do ranking com gradiente correspondente.
class MedalBadge extends StatelessWidget {
  final int position;
  final double size;
  const MedalBadge({super.key, required this.position, this.size = 36});

  @override
  Widget build(BuildContext context) {
    String emoji;
    List<Color> colors;
    switch (position) {
      case 1:
        emoji = '🥇';
        colors = const [Color(0xFFFFD54F), Color(0xFFFFB300)];
        break;
      case 2:
        emoji = '🥈';
        colors = const [Color(0xFFE0E0E0), Color(0xFF9E9E9E)];
        break;
      case 3:
        emoji = '🥉';
        colors = const [Color(0xFFD7A46B), Color(0xFF8D5A2B)];
        break;
      default:
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Text(
            '$position',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: size * 0.4,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.55)),
    );
  }
}

/// Pill de título (badge do sistema de títulos).
class TitleBadge extends StatelessWidget {
  final String emoji;
  final String name;
  final bool compact;
  const TitleBadge({
    super.key,
    required this.emoji,
    required this.name,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1FB45C).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: const Color(0xFF1FB45C).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: compact ? 12 : 14)),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1FB45C),
            ),
          ),
        ],
      ),
    );
  }
}
