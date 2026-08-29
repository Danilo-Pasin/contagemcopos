import 'package:flutter/material.dart';

/// Logo do app.
///
/// Mostra a imagem em `assets/logo.png` (a logo "C" da marca). Troque o arquivo
/// `assets/logo.png` pelo PNG final da logo e ela passa a ser usada em todo o
/// app automaticamente. Se o asset ainda não estiver disponível, mostra o emoji
/// de bebida como fallback.
///
/// O bloco de fundo é configurável via [background] — na home é preto para
/// destacar a logo verde; outras superfícies (ex.: prompt de instalação) usam
/// o verde da marca por padrão.
class AppLogo extends StatelessWidget {
  final double size;
  final EdgeInsets padding;

  /// Cor do bloco atrás da logo. O tom mais claro do gradiente e o brilho são
  /// derivados dela.
  final Color background;

  const AppLogo({
    super.key,
    this.size = 120,
    this.padding = EdgeInsets.zero,
    this.background = const Color(0xFF1FB45C),
  });

  @override
  Widget build(BuildContext context) {
    final end = Color.lerp(background, Colors.white, 0.3)!;
    return Container(
      width: size,
      height: size,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [background, end],
        ),
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: [
          BoxShadow(
            color: background.withValues(alpha: 0.5),
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
