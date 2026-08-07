/// Referência fixa usada quando o grupo é criado "sem meta", apenas para
/// manter as faixas de título (Aprendiz, Cachaceiro…) funcionando.
const int kNoGoalMaxGoal = 20;

/// Representa uma faixa de título do sistema proporcional.
class TitleTier {
  final String id;
  final String emoji;
  final String name;
  final double percentage; // % da meta máxima

  const TitleTier({
    required this.id,
    required this.emoji,
    required this.name,
    required this.percentage,
  });

  /// Quantidade de bebidas necessária para atingir este título.
  int requiredDrinks(int maxGoal) {
    // Sem meta (0 ou negativo), usa a referência fixa das faixas.
    final goal = maxGoal <= 0 ? kNoGoalMaxGoal : maxGoal;
    return (goal * percentage / 100).ceil();
  }

  @override
  String toString() => '$emoji $name';
}

/// Catálogo de títulos (faixas) do sistema.
class TitleSystem {
  const TitleSystem._();

  static const List<TitleTier> tiers = [
    TitleTier(id: 'aprendiz', emoji: '🍺', name: 'Aprendiz', percentage: 10),
    TitleTier(id: 'cachaceiro', emoji: '🍻', name: 'Cachaceiro', percentage: 25),
    TitleTier(id: 'rei_boteco', emoji: '👑', name: 'Rei do Boteco', percentage: 50),
    TitleTier(id: 'lenda', emoji: '💀', name: 'Lenda', percentage: 75),
    TitleTier(id: 'imperador', emoji: '🏆', name: 'Imperador do Copo', percentage: 100),
    TitleTier(id: 'mito', emoji: '🔥', name: 'Mito do Bar', percentage: 120),
    TitleTier(id: 'deus', emoji: '👑👑', name: 'Deus da Geladeira', percentage: 150),
  ];

  /// Retorna o título atual com base na contagem e na meta máxima.
  static TitleTier currentTier(int drinks, int maxGoal) {
    TitleTier result = tiers.first;
    for (final t in tiers) {
      if (drinks >= t.requiredDrinks(maxGoal)) {
        result = t;
      }
    }
    return result;
  }

  /// Retorna o próximo título a ser alcançado (ou null se já no topo).
  static TitleTier? nextTier(int drinks, int maxGoal) {
    for (final t in tiers) {
      if (drinks < t.requiredDrinks(maxGoal)) return t;
    }
    return null;
  }

  /// Progresso (0..1) entre o título atual e o próximo.
  static double progressToNext(int drinks, int maxGoal) {
    final cur = currentTier(drinks, maxGoal);
    final nxt = nextTier(drinks, maxGoal);
    if (nxt == null) return 1;
    final curReq = cur.requiredDrinks(maxGoal);
    final nxtReq = nxt.requiredDrinks(maxGoal);
    if (nxtReq == curReq) return 1;
    return ((drinks - curReq) / (nxtReq - curReq)).clamp(0.0, 1.0);
  }
}
