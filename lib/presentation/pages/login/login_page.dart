import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/app_validator.dart';
import '../../providers/core_providers.dart';
import '../../providers/identity_provider.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/responsive_content.dart';

/// Entrada rápida para quem JÁ é membro de um grupo: digita código, nome e
/// senha (os mesmos usados ao entrar/criar) e cai direto no perfil do grupo.
class LoginGroupPage extends ConsumerStatefulWidget {
  final String initialCode;
  const LoginGroupPage({super.key, this.initialCode = ''});

  @override
  ConsumerState<LoginGroupPage> createState() => _LoginGroupPageState();
}

class _LoginGroupPageState extends ConsumerState<LoginGroupPage> {
  late final TextEditingController _codeCtrl;
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.initialCode);
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool get _valid =>
      AppValidator.canSubmitLogin(
        code: _codeCtrl.text,
        name: _nameCtrl.text,
        password: _passCtrl.text,
      ) &&
      !_busy;

  Future<void> _login() async {
    if (!_valid) return;
    setState(() => _busy = true);
    try {
      final code = _codeCtrl.text.trim().toUpperCase();
      final identityNotifier = ref.read(identityProvider.notifier);
      final groupRepo = ref.read(groupRepositoryProvider);

      final group = await groupRepo.getGroupByCode(code);
      if (group == null) throw Exception('Grupo não encontrado.');

      final accountId = await groupRepo.ensureAccount(
        name: _nameCtrl.text.trim(),
        password: _passCtrl.text,
      );

      final me = await groupRepo.findMemberByAccount(group.id, accountId);
      if (me == null) {
        throw Exception(
          'Você ainda não é membro deste grupo com esse nome/senha.',
        );
      }

      await identityNotifier.saveProfile(
        name: _nameCtrl.text.trim(),
        accountId: accountId,
      );
      await identityNotifier.rememberMember(group.code, me.id);

      if (mounted) context.go(AppRoutes.group(group.code));
    } catch (e) {
      if (mounted) context.showSnack('Erro: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Já estou em um grupo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContent(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sm),
                const Text('🔐', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 52)),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Entre com o código do grupo,\nseu nome e senha.',
                  textAlign: TextAlign.center,
                  style: context.tt.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Código do grupo',
                    hintText: 'Ex: NXGUZN',
                    prefixIcon: Icon(Icons.tag),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Seu nome',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _valid ? _login() : null,
                  decoration: InputDecoration(
                    labelText: 'Sua senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Use o mesmo nome e senha que você cadastrou ao criar ou '
                  'entrar no grupo.',
                  style: context.tt.bodySmall?.copyWith(
                      color: context.cs.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Entrar',
                  icon: Icons.login_rounded,
                  loading: _busy,
                  onPressed: _valid ? _login : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.home),
                    child: const Text('Criar grupo ou entrar em um novo'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}