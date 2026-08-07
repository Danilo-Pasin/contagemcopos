import 'package:flutter/material.dart';
import '../../core/theme/app_tokens.dart';

/// Botão primário com gradiente e cantos arredondados.
///
/// Padrão do app: em telas largas o botão não estica por toda a tela — ele
/// preenche o espaço disponível até [maxButtonWidth] e se centraliza.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expanded;
  final double height;
  final double? maxWidth;
  final LinearGradient? gradient;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
    this.height = AppButtonSizes.regular,
    this.maxWidth,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    final grad = gradient ?? AppGradients.primary;

    final button = Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Container(
        height: height,
        width: expanded ? double.infinity : null,
        decoration: BoxDecoration(
          gradient: grad,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF1FB45C).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: disabled ? null : onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    // Em modo expandido, limita a largura (padrão do app) e centraliza.
    if (expanded) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? AppLayout.maxButtonWidth,
          ),
          child: button,
        ),
      );
    }
    return button;
  }
}

/// Botão secundário (contorno) — mesmo padrão de largura/tamanho.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? maxWidth;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 20) : const SizedBox.shrink(),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        // Preenche toda a largura (dentro do ConstrainedBox abaixo), assim o
        // secundário fica com o MESMO tamanho do primário.
        minimumSize: const Size(double.infinity, AppButtonSizes.regular),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? AppLayout.maxButtonWidth,
        ),
        child: button,
      ),
    );
  }
}
