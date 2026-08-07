import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../providers/core_providers.dart';
import '../../providers/identity_provider.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_states.dart';
import '../../widgets/responsive_content.dart';

class JoinGroupPage extends ConsumerStatefulWidget {
  final String code;
  const JoinGroupPage({super.key, required this.code});

  @override
  ConsumerState<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends ConsumerState<JoinGroupPage> {
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _photoUrl;
  bool _loading = true;
  bool _joining = false;
  bool _obscurePass = true;
  String? _groupName;
  String? _error;
  String? _accountId;

  bool get _canJoin =>
      _nameCtrl.text.trim().isNotEmpty &&
      _passCtrl.text.length >= 5 &&
      !_joining;

  @override
  void initState() {
    super.initState();
    _accountId = ref.read(identityProvider).accountId;
    _load();
  }

  Future<void> _load() async {
    try {
      final identity = ref.read(identityProvider);

      final groupRepo = ref.read(groupRepositoryProvider);
      final group = await groupRepo.getGroupByCode(widget.code);

      if (group == null) {
        setState(() {
          _error = 'Grupo não encontrado.';
          _loading = false;
        });
        return;
      }

      _groupName = group.name;

      if (identity.savedName.isNotEmpty) {
        _nameCtrl.text = identity.savedName;
        _photoUrl = identity.savedPhoto;
      }

      // Já sou membro (conta reconhecida no dispositivo)? Entra direto.
      if (_accountId != null) {
        final me = await groupRepo.findMemberByAccount(group.id, _accountId!);
        if (me != null) {
          await ref
              .read(identityProvider.notifier)
              .rememberMember(widget.code, me.id);
          if (mounted) {
            context.go(AppRoutes.group(widget.code));
            return;
          }
        }
      }

      // Fallback: conta por anon_id (perfil legado).
      if (_accountId == null && identity.anonId != null) {
        final me = await groupRepo.findMember(group.id, identity.anonId!);
        if (me != null) {
          await ref
              .read(identityProvider.notifier)
              .rememberMember(widget.code, me.id);
          if (mounted) {
            context.go(AppRoutes.group(widget.code));
            return;
          }
        }
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (file == null) return;
      final identity = ref.read(identityProvider);
      final storage = ref.read(storageServiceProvider);
      final url = await storage.uploadAvatar(identity.anonId!, file);
      setState(() => _photoUrl = url);
    } catch (e) {
      context.showSnack('Erro: $e', isError: true);
    }
  }

  Future<void> _join() async {
    if (!_canJoin) return;
    setState(() => _joining = true);
    try {
      final identityNotifier = ref.read(identityProvider.notifier);
      final identity = ref.read(identityProvider);
      final groupRepo = ref.read(groupRepositoryProvider);
      final group = await groupRepo.getGroupByCode(widget.code);

      // Garante a conta nome+senha (cria se novo, valida se já existe).
      final accountId = await groupRepo.ensureAccount(
        name: _nameCtrl.text.trim(),
        password: _passCtrl.text,
      );

      // Já é membro do grupo com essa conta? Entra direto.
      var me = await groupRepo.findMemberByAccount(group!.id, accountId);
      if (me == null) {
        me = await groupRepo.joinGroup(
          group: group,
          anonId: identity.anonId!,
          name: _nameCtrl.text.trim(),
          accountId: accountId,
          photoUrl: _photoUrl,
        );
      }

      await identityNotifier.saveProfile(
        name: _nameCtrl.text.trim(),
        photoUrl: _photoUrl,
        accountId: accountId,
      );
      await identityNotifier.rememberMember(widget.code, me.id);

      if (mounted) context.go(AppRoutes.group(widget.code));
    } catch (e) {
      context.showSnack('Erro ao entrar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_groupName ?? 'Entrar no grupo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContent(
          child: _loading
              ? const AppLoading(label: 'Carregando grupo...')
              : _error != null
                  ? EmptyState(
                      emoji: '🤔',
                      title: _error!,
                      action: PrimaryButton(
                        label: 'Voltar ao início',
                        onPressed: () => context.go(AppRoutes.home),
                      ),
                    )
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          '🍻',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 56),
                        ).animate().scale(duration: 500.ms),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _groupName ?? '',
                          textAlign: TextAlign.center,
                          style: context.tt.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Você foi convidado para a competição!',
                          textAlign: TextAlign.center,
                          style: context.tt.bodyMedium
                              ?.copyWith(color: context.cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Center(
                          child: GestureDetector(
                            onTap: _pickPhoto,
                            child: AppAvatar(
                              photoUrl: _photoUrl,
                              name: _nameCtrl.text.isEmpty
                                  ? '?'
                                  : _nameCtrl.text,
                              radius: 48,
                            ),
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                        TextButton(
                          onPressed: _pickPhoto,
                          child: const Text('Adicionar foto (opcional)'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Seu nome',
                            hintText: 'Como vão te chamar?',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          onChanged: (_) => setState(() {}),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscurePass,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _canJoin ? _join() : null,
                          decoration: InputDecoration(
                            labelText: 'Crie sua senha (mín. 5)',
                            hintText: 'Você usará para voltar ao seu perfil',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePass
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: () => setState(
                                  () => _obscurePass = !_obscurePass),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.1),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Já participa deste grupo? Use o MESMO nome e senha '
                          'para recuperar seu perfil.',
                          style: context.tt.bodySmall?.copyWith(
                              color: context.cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        PrimaryButton(
                          label: 'Entrar no grupo',
                          icon: Icons.login_rounded,
                          loading: _joining,
                          onPressed: _canJoin ? _join : null,
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
