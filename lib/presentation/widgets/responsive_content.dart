import 'package:flutter/material.dart';
import '../../core/theme/app_tokens.dart';

/// Wrapper responsivo que centraliza e limita a largura do conteúdo.
///
/// Garante que o conteúdo não se estique por toda a tela em telas largas
/// (desktop/tablet), mantendo legibilidade; em telas estreitas (mobile) ocupa a
/// largura disponível. Compatível com [CustomScrollView] e [SingleChildScrollView].
class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.maxContentWidth,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}