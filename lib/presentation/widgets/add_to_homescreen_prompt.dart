import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/platform_detector.dart';
import 'app_buttons.dart';
import 'app_logo.dart';

/// Prompt/tutorial de instalação do PWA ("Adicionar à Tela de Início").
///
/// Mostra um bottom sheet uma única vez (até ser dispensado), apenas em web
/// mobile e quando o app ainda não roda como PWA instalado. Se o navegador
/// oferece o prompt nativo (`beforeinstallprompt`), além do tutorial manual
/// há o botão de instalação direta.
class AddToHomescreenPrompt {
  AddToHomescreenPrompt._();

  static const _dismissedKey = 'adhs_dismissed_v1';
  static bool _attemptedThisSession = false;

  /// Exibe o prompt se apropriado: primeira visita à home, web mobile,
  /// fora do modo standalone.
  static Future<void> showIfAppropriate(BuildContext context) async {
    if (_attemptedThisSession) return;
    if (!PlatformDetector.isWeb || !PlatformDetector.isWebMobile) return;
    if (PlatformDetector.isPWA) return;

    _attemptedThisSession = true;
    initInstallPromptListener();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_dismissedKey) == true) return;
      if (!context.mounted) return;

      final dismissed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (_) => AddToHomescreenSheet(
          hasNativeInstall: hasDeferredInstall,
          iosSafari: PlatformDetector.isIOS && PlatformDetector.isSafari,
        ),
      );

      if (dismissed == true && context.mounted) {
        await prefs.setBool(_dismissedKey, true);
      }
    } catch (e) {
      debugPrint('[AddToHomescreenPrompt] Erro ao exibir tutorial: $e');
    }
  }
}

/// Bottom sheet do tutorial — flags injetáveis para testes de widget
/// (no app real são preenchidas pelo [AddToHomescreenPrompt]).
class AddToHomescreenSheet extends StatelessWidget {
  final bool hasNativeInstall;
  final bool iosSafari;

  const AddToHomescreenSheet({
    super.key,
    this.hasNativeInstall = false,
    this.iosSafari = false,
  });

  Future<void> _install(BuildContext context) async {
    await nativeInstall();
    if (context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 12, AppSpacing.lg,
              AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppLogo(size: 72, background: Colors.black),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Instale o ${AppBrand.name}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                hasNativeInstall
                    ? 'Instale para uma experiência completa de app.'
                    : 'Adicione à tela inicial para usar como app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (hasNativeInstall)
                _NativeInstallSection(onInstall: () => _install(context))
              else ...[
                _TutorialSteps(iosSafari: iosSafari),
                const SizedBox(height: AppSpacing.xl),
              ],
              SecondaryButton(
                label: hasNativeInstall ? 'Agora não' : 'Entendi',
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NativeInstallSection extends StatelessWidget {
  final VoidCallback onInstall;
  const _NativeInstallSection({required this.onInstall});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        PrimaryButton(
          label: 'Instalar app',
          icon: Icons.download_rounded,
          onPressed: onInstall,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Icon(Icons.info_outline_rounded,
                size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Se não aparecer a opção, siga o tutorial manual abaixo.',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const _TutorialSteps(),
      ],
    );
  }
}

class _TutorialSteps extends StatelessWidget {
  final bool iosSafari;
  const _TutorialSteps({this.iosSafari = false});

  @override
  Widget build(BuildContext context) {
    if (iosSafari) {
      return Column(
        children: [
          _StepWidget(
            step: 1,
            icon: Icons.ios_share_rounded,
            text: 'Toque no botão Compartilhar',
          ),
          const SizedBox(height: AppSpacing.md),
          _StepWidget(
            step: 2,
            icon: Icons.add_to_home_screen_rounded,
            text: 'Role e toque em "Adicionar à Tela de Início"',
          ),
        ],
      );
    }
    return Column(
      children: [
        _StepWidget(
          step: 1,
          icon: Icons.more_vert_rounded,
          text: 'Toque no menu (⋮) do navegador',
        ),
        const SizedBox(height: AppSpacing.md),
        _StepWidget(
          step: 2,
          icon: Icons.share_rounded,
          text: 'Toque em "Compartilhar"',
        ),
        const SizedBox(height: AppSpacing.md),
        _StepWidget(
          step: 3,
          icon: Icons.add_to_home_screen_rounded,
          text: 'Toque em "Adicionar à tela inicial"',
        ),
      ],
    );
  }
}

class _StepWidget extends StatelessWidget {
  final int step;
  final IconData icon;
  final String text;

  const _StepWidget({
    required this.step,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: cs.primary, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            gradient: AppGradients.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
