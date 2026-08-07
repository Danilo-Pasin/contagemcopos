import 'package:flutter/material.dart';

/// Logo do app.
///
/// Mostra a imagem em `assets/logo.png` (a logo "C" da marca). Troque o arquivo
/// `assets/logo.png` pelo PNG final da logo e ela passa a ser usada em todo o
/// app automaticamente. Se o asset ainda não estiver disponível, mostra o emoji
/// de bebida como fallback.
class AppLogo extends StatelessWidget {
  final double size;
  final EdgeInsets padding;

  const AppLogo({super.key, this.size = 120, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1FB45C),
            const Color(0xFF48E37F),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1FB45C).withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.24),
        child: Image.asset(
          'assets/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Text('🍺', style: TextStyle(fontSize: 60)),
          ),
        ),
      ),
    );
  }
}