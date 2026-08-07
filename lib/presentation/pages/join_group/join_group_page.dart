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
  String? _photoUrl;
  bool _loading = true;
  bool _joining = false;
  String? _groupName;
  String? _error;
  bool _alreadyMember = false;

  @override
  void initState() {
    super.initState();
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

      if (identity.anonId != null) {
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
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _joining = true);
    try {
      final identityNotifier = ref.read(identityProvider.notifier);
      final identity = ref.read(identityProvider);
      final groupRepo = ref.read(groupRepositoryProvider);
      final group = await groupRepo.getGroupByCode(widget.code);

      await groupRepo.joinGroup(
        group: group!,
        anonId: identity.anonId!,
        name: _nameCtrl.text.trim(),
        photoUrl: _photoUrl,
      );

      await identityNotifier.saveProfile(
          name: _nameCtrl.text.trim(), photoUrl: _photoUrl);

      // busca o participante recém-criado para registrar localmente
      final me = await groupRepo.findMember(group.id, identity.anonId!);
      if (me != null) {
        await identityNotifier.rememberMember(widget.code, me.id);
      }

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
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Seu nome',
                            hintText: 'Como vão te chamar?',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          onChanged: (_) => setState(() {}),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                        const SizedBox(height: AppSpacing.xl),
                        PrimaryButton(
                          label: 'Entrar no grupo',
                          icon: Icons.login_rounded,
                          loading: _joining,
                          onPressed: _nameCtrl.text.trim().isEmpty
                              ? null
                              : _join,
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
