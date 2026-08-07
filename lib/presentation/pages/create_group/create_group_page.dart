import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/competition_periods.dart';
import '../../../core/constants/title_system.dart';
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
  final _passCtrl = TextEditingController();
  final _customValueCtrl = TextEditingController(text: '1');
  final _goalCtrl = TextEditingController(text: '12');
  CompetitionPeriod? _period;
  bool _customMode = false;
  int _customValue = 1;
  DurationUnit _customUnit = DurationUnit.days;
  bool _goalEnabled = false;
  bool _obscurePass = true;
  String? _photoUrl;
  String _coverEmoji = '🍻';
  bool _creating = false;

  static const _emojis = ['🍻', '🍺', '🍷', '🥃', '🍹', '🥂', '🍾', '🍸'];

  /// Período em vigor (personalizado construído na hora ou um preset escolhido).
  CompetitionPeriod? get _chosen {
    if (_customMode) {
      return CompetitionPeriod(
        id: 'custom',
        label: 'Personalizado',
        value: _customValue,
        unit: _customUnit,
      );
    }
    return _period;
  }

  Duration get _chosenDuration {
    final c = _chosen;
    if (c == null) return Duration.zero;
    return Duration(hours: c.totalHours);
  }

  int get _durationDays {
    final c = _chosen;
    if (c == null || c.totalHours <= 0) return 0;
    return (c.totalHours / 24).round().clamp(1, 999999);
  }

  int get _maxGoal => _goalEnabled ? _goalValue : kNoGoalMaxGoal;

  /// Valor digitado pelo usuário para a meta (quando "por meta").
  int get _goalValue => int.tryParse(_goalCtrl.text.trim()) ?? 0;

  String get _durationLabel {
    final c = _chosen;
    if (c == null) return '';
    switch (c.unit) {
      case DurationUnit.hours:
        return '${c.value} horas';
      case DurationUnit.days:
        return c.value == 1 ? '1 dia' : '${c.value} dias';
      case DurationUnit.months:
        return c.value == 1 ? '1 mês' : '${c.value} meses';
    }
  }

  double get _drinksPerDay {
    final c = _chosen;
    if (c == null || c.totalHours <= 0) return 0;
    return c.maxGoal / (c.totalHours / 24);
  }

  bool get _canCreate =>
      _groupNameCtrl.text.trim().isNotEmpty &&
      _nameCtrl.text.trim().isNotEmpty &&
      _passCtrl.text.length >= 5 &&
      _durationDays > 0 &&
      _customValue > 0 &&
      (!_goalEnabled || _goalValue > 0) &&
      !_creating;

  @override
  void dispose() {
    _groupNameCtrl.dispose();
    _nameCtrl.dispose();
    _passCtrl.dispose();
    _customValueCtrl.dispose();
    _goalCtrl.dispose();
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
      final end = now.add(_chosenDuration);

      final group = await groupRepo.createGroup(
        anonId: anonId,
        name: _groupNameCtrl.text.trim(),
        startDate: now,
        endDate: end,
        durationDays: _durationDays,
        maxGoal: _maxGoal,
        coverEmoji: _coverEmoji,
      );

      // Cria/valida a conta nome+senha do criador.
      final accountId = await groupRepo.ensureAccount(
        name: _nameCtrl.text.trim(),
        password: _passCtrl.text,
      );

      final participant = await groupRepo.joinGroup(
        group: group,
        anonId: anonId,
        name: _nameCtrl.text.trim(),
        accountId: accountId,
        photoUrl: _photoUrl,
        isCreator: true,
      );

      await identity.saveProfile(
        name: _nameCtrl.text.trim(),
        photoUrl: _photoUrl,
        accountId: accountId,
      );
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
                onSelected: (sel) {
                  setState(() {
                    _customMode = sel;
                    if (sel) _period = null;
                  });
                },
              ),
              if (_customMode) ...[
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Defina seu período',
                        style: context.tt.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customValueCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Quantidade',
                                prefixIcon: Icon(Icons.numbers_rounded),
                              ),
                              onChanged: (v) => setState(() {
                                _customValue =
                                    int.tryParse(v.trim()) ?? 0;
                              }),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DropdownButtonFormField<DurationUnit>(
                              initialValue: _customUnit,
                              decoration: const InputDecoration(
                                labelText: 'Unidade',
                                prefixIcon: Icon(Icons.schedule_rounded),
                              ),
                              items: DurationUnit.values
                                  .map((u) => DropdownMenuItem(
                                        value: u,
                                        child: Text(u.pluralLabel),
                                      ))
                                  .toList(),
                              onChanged: (u) {
                                if (u == null) return;
                                setState(() => _customUnit = u);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              if (_chosen != null && _durationDays > 0)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Text(_goalEnabled ? '🎯' : '🆓',
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _goalEnabled
                                    ? 'Meta por pessoa: $_goalValue bebidas'
                                    : 'Sem meta definida',
                                style: context.tt.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '$_durationLabel · '
                                '${_drinksPerDay.toStringAsFixed(1)} beb/dia',
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
              const SizedBox(height: AppSpacing.lg),

              _SectionTitle('Meta da competição'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('🆓 Sem meta'),
                    selected: !_goalEnabled,
                    onSelected: (_) => setState(() => _goalEnabled = false),
                  ),
                  ChoiceChip(
                    label: const Text('🎯 Por meta'),
                    selected: _goalEnabled,
                    onSelected: (_) => setState(() => _goalEnabled = true),
                  ),
                ],
              ),
              if (_goalEnabled) ...[
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _goalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Meta por pessoa (bebidas)',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Os títulos (Aprendiz, Cachaceiro…) são calculados como '
                  'faixas dessa meta. Sem meta, usamos uma referência fixa.',
                  style: context.tt.bodySmall?.copyWith(
                      color: context.cs.onSurfaceVariant),
                ),
              ],
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
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: 'Crie sua senha (mín. 5)',
                  hintText: 'Você usará para voltar ao seu perfil',
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
