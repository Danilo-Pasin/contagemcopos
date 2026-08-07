/// Unidade de duração usada no período personalizado.
enum DurationUnit {
  hours('horas', 1),
  days('dias', 24),
  months('meses', 720); // ~30 dias

  const DurationUnit(this.pluralLabel, this.hoursPerOne);

  /// Rótulo plural exibido na UI.
  final String pluralLabel;

  /// Quantas horas equivalem a 1 unidade.
  final int hoursPerOne;
}

/// Período de competição, seja um preset ou um período personalizado.
class CompetitionPeriod {
  final String id;
  final String label;
  final int value;
  final DurationUnit unit;

  /// Meta máxima 'curtida' (se null, calculada a partir das horas).
  final int? goal;

  const CompetitionPeriod({
    required this.id,
    required this.label,
    required this.value,
    required this.unit,
    this.goal,
  });

  /// Duração total em horas.
  int get totalHours => value * unit.hoursPerOne;

  /// Dias inteiros aproximados (mín. 1), usado p/ persistência e datas.
  int get durationDays => (totalHours / 24).round().clamp(1, 999999);

  /// Meta máxima de bebidas (usa `goal` fixa dos preset ou ~3,3/dia).
  int get maxGoal => goal ??
      ((totalHours / 24) * 3.3).round().clamp(1, 999999);

  static const List<CompetitionPeriod> presets = [
    CompetitionPeriod(id: '8h', label: '8 horas', value: 8, unit: DurationUnit.hours, goal: 6),
    CompetitionPeriod(id: '1d', label: '1 dia', value: 1, unit: DurationUnit.days, goal: 12),
    CompetitionPeriod(id: '1w', label: '1 semana', value: 7, unit: DurationUnit.days, goal: 40),
    CompetitionPeriod(id: '15d', label: '15 dias', value: 15, unit: DurationUnit.days, goal: 60),
    CompetitionPeriod(id: '1m', label: '1 mês', value: 1, unit: DurationUnit.months, goal: 100),
    CompetitionPeriod(id: '3m', label: '3 meses', value: 3, unit: DurationUnit.months, goal: 260),
  ];
}