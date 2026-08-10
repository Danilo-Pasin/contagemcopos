import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../providers/identity_provider.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/responsive_content.dart';

class EnterGroupPage extends ConsumerStatefulWidget {
  const EnterGroupPage({super.key});

  @override
  ConsumerState<EnterGroupPage> createState() => _EnterGroupPageState();
}

class _EnterGroupPageState extends ConsumerState<EnterGroupPage> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  String _normalize(String raw) =>
      raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

  void _submit() {
    final code = _normalize(_codeCtrl.text);
    if (code.isEmpty) return;
    context.push(AppRoutes.join(code));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0E2A1A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrar em um grupo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppGradients.hero : AppGradients.heroLight,
        ),
        child: SafeArea(
          child: ResponsiveContent(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.group_add_rounded,
                        size: 52, color: fg.withValues(alpha: 0.8)),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Digite o código que você recebeu para entrar.\nEle normalmente tem 6 letras e números.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: fg.withValues(alpha: 0.7),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextField(
                      controller: _codeCtrl,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 4),
                      decoration: InputDecoration(
                        hintText: 'ABC123',
                        filled: true,
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: 'Continuar',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _submit,
                    )
                        .animate()
                        .fadeIn(delay: 100.ms)
                        .slideY(begin: 0.2, duration: 300.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}