import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/competition_periods.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../providers/core_providers.dart';
import '../../providers/identity_provider.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/responsive_content.dart';

class CreateGroupPage extends ConsumerStatefulWidget {
  const CreateGroupPage({super.key});

  @override
  ConsumerState<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends ConsumerState<CreateGroupPage> {
  final _groupNameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  CompetitionPeriod? _period;
  bool _customMode = false;
  DateTime? _customStart;
  DateTime? _customEnd;
  String? _photoUrl;
  String _coverEmoji = '🍻';
  bool _creating = false;

  static const _emojis = ['🍻', '🍺', '🍷', '🥃', '🍹', '🥂', '🍾', '🍸'];

  int get _durationDays {
    if (_customMode && _customStart != null && _customEnd != null) {
      return _customEnd!.difference(_customStart!).inDays + 1;
    }
    return _period?.days ?? 0;
  }

  int get _maxGoal {
    if (_customMode) return CompetitionPeriod.customGoal(_durationDays);
    return _period?.maxGoal ?? 0;
  }

  bool get _canCreate =>
      _groupNameCtrl.text.trim().isNotEmpty &&
      _nameCtrl.text.trim().isNotEmpty &&
      _durationDays > 0 &&
      !_creating;

  @override
  void dispose() {
    _groupNameCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
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
      final url =
          await storage.uploadAvatar(identity.anonId!, file);
      setState(() => _photoUrl = url);
    } catch (e) {
      context.showSnack('Erro ao enviar foto: $e', isError: true);
    }
  }

  Future<void> _create() async {
    if (!_canCreate) return;
    setState(() => _creating = true);
    try {
      final identity = ref.read(identityProvider.notifier);
      // Garante que a sessão anônima está pronta antes de prosseguir
      final anonId = await identity.ensureReady();
      final groupRepo = ref.read(groupRepositoryProvider);

      final now = DateTime.now();
      final start = _customMode ? _customStart! : now;
      final end = _customMode
          ? _customEnd!
          : now.add(Duration(days: _durationDays));

      final group = await groupRepo.createGroup(
        anonId: anonId,
        name: _groupNameCtrl.text.trim(),
        startDate: start,
        endDate: end,
        durationDays: _durationDays,
        maxGoal: _maxGoal,
        coverEmoji: _coverEmoji,
      );

      final participant = await groupRepo.joinGroup(
        group: group,
        anonId: anonId,
        name: _nameCtrl.text.trim(),
        photoUrl: _photoUrl,
        isCreator: true,
      );

      await identity.saveProfile(name: _nameCtrl.text.trim(), photoUrl: _photoUrl);
      await identity.rememberMember(group.code, participant.id);

      if (mounted) {
        context.go(AppRoutes.group(group.code));
      }
    } catch (e) {
      debugPrint('[CreateGroup] erro: $e');
      if (mounted) context.showSnack('Erro ao criar grupo: $e', isError: true);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Grupo')),
      body: SafeArea(
        child: ResponsiveContent(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionTitle('Nome do grupo'),
              TextField(
                controller: _groupNameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Ex: Churrasco do Danilo',
                  prefixIcon: Icon(Icons.groups_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ).animate().fadeIn().slideX(begin: -0.1, duration: 300.ms),
              const SizedBox(height: AppSpacing.lg),

              _SectionTitle('Ícone'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _emojis.map((e) {
                  final selected = e == _coverEmoji;
                  return GestureDetector(
                    onTap: () => setState(() => _coverEmoji = e),
                    child: AnimatedContainer(
                      duration: 250.ms,
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: selected
                            ? context.cs.primaryContainer
                            : context.cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: selected
                            ? Border.all(color: context.cs.primary, width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(e, style: const TextStyle(fontSize: 26)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),

              _SectionTitle('Período da competição'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: CompetitionPeriod.presets.map((p) {
                  final selected = _period?.id == p.id && !_customMode;
                  return ChoiceChip(
                    label: Text(p.label),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() {
                      _period = p;
                      _customMode = false;
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              ChoiceChip(
                label: const Text('📅 Personalizado'),
                selected: _customMode,
                onSelected: (_) async {
                  final now = DateTime.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365)),
                    initialDateRange: DateTimeRange(
                      start: now,
                      end: now.add(const Duration(days: 7)),
                    ),
                    locale: const Locale('pt', 'BR'),
                  );
                  if (picked != null) {
                    setState(() {
                      _customMode = true;
                      _customStart = picked.start;
                      _customEnd = picked.end;
                    });
                  }
                },
              ),
              if (_durationDays > 0)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        const Text('🎯', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Meta máxima: $_maxGoal bebidas',
                                style: context.tt.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '$_durationDays dias · '
                                '${(_maxGoal / _durationDays).toStringAsFixed(1)} beb/dia',
                                style: context.tt.bodySmall?.copyWith(
                                    color: context.cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),

              _SectionTitle('Seu perfil'),
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickProfilePhoto,
                    child: AppAvatar(
                      photoUrl: _photoUrl,
                      name: _nameCtrl.text.isEmpty ? '?' : _nameCtrl.text,
                      radius: 36,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Seu nome',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  IconButton(
                    onPressed: _pickProfilePhoto,
                    icon: const Icon(Icons.camera_alt_outlined),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              PrimaryButton(
                label: 'Criar e entrar',
                icon: Icons.rocket_launch_rounded,
                loading: _creating,
                onPressed: _canCreate ? _create : null,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: context.tt.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: context.cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
