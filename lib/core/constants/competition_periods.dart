/// Período de competição pré-definido.
class CompetitionPeriod {
  final String id;
  final String label;
  final int days;
  final int maxGoal;

  const CompetitionPeriod({
    required this.id,
    required this.label,
    required this.days,
    required this.maxGoal,
  });

  static const List<CompetitionPeriod> presets = [
    CompetitionPeriod(id: '1d', label: '1 dia', days: 1, maxGoal: 12),
    CompetitionPeriod(id: '2d', label: '2 dias', days: 2, maxGoal: 24),
    CompetitionPeriod(id: '3d', label: '3 dias', days: 3, maxGoal: 36),
    CompetitionPeriod(id: '1w', label: '1 semana', days: 7, maxGoal: 40),
    CompetitionPeriod(id: '15d', label: '15 dias', days: 15, maxGoal: 60),
    CompetitionPeriod(id: '1m', label: '1 mês', days: 30, maxGoal: 100),
    CompetitionPeriod(id: '2m', label: '2 meses', days: 60, maxGoal: 180),
    CompetitionPeriod(id: '3m', label: '3 meses', days: 90, maxGoal: 260),
  ];

  /// Calcula a meta máxima para um período personalizado (~3,3 bebidas/dia).
  static int customGoal(int days) => (days * 3.3).round();
}
