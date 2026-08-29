/// Referência fixa usada quando o grupo é criado "sem meta", apenas para
/// manter a compatibilidade do fluxo (não participa das faixas de título,
/// que agora são por quantidade fixa de copos).
const int kNoGoalMaxGoal = 20;

/// Representa uma faixa de título (patamar fixo em quantidade de copos).
class TitleTier {
  final String id;
  final String emoji;
  final String name;
  final int required; // copos necessários para atingir

  const TitleTier({
    required this.id,
    required this.emoji,
    required this.name,
    required this.required,
  });

  /// Quantidade de bebidas necessária para atingir este título.
  ///
  /// Patamar fixo em copos — não depende da meta do grupo.
  int requiredDrinks(int maxGoal) => required;

  @override
  String toString() => '$emoji $name';
}

/// Catálogo de títulos (faixas) do sistema — por quantidade absoluta de copos.
class TitleSystem {
  const TitleSystem._();

  static const List<TitleTier> tiers = [
    TitleTier(id: 'aprendiz', emoji: '🍺', name: 'Aprendiz', required: 1),
    TitleTier(id: 'cachaceiro', emoji: '🍻', name: 'Cachaceiro', required: 3),
    TitleTier(id: 'alcoolatra', emoji: '🤌', name: 'Alcoólatra', required: 6),
    TitleTier(id: 'lenda', emoji: '💀', name: 'Lenda', required: 9),
    TitleTier(id: 'reabilitacao', emoji: '🙏', name: 'Papo de Reabilitação', required: 12),
  ];

  /// Patamares efetivos (monotônicos) para uma meta.
  ///
  /// Como os patamares são fixos e crescentes, o carry-forward é apenas uma
  /// rede de segurança extra.
  static List<int> thresholdsFor(int maxGoal) {
    final out = <int>[];
    var prev = 0;
    for (final t in tiers) {
      final req = t.required;
      final eff = req < prev ? prev : req;
      prev = eff;
      out.add(eff);
    }
    return out;
  }

  /// Retorna o título atual com base na contagem.
  static TitleTier currentTier(int drinks, int maxGoal) {
    final reqs = thresholdsFor(maxGoal);
    TitleTier result = tiers.first;
    for (var i = 0; i < tiers.length; i++) {
      if (drinks >= reqs[i]) result = tiers[i];
    }
    return result;
  }

  /// Retorna o próximo título a ser alcançado (ou null se já no topo).
  static TitleTier? nextTier(int drinks, int maxGoal) {
    final reqs = thresholdsFor(maxGoal);
    for (var i = 0; i < tiers.length; i++) {
      if (drinks < reqs[i]) return tiers[i];
    }
    return null;
  }

  /// Progresso (0..1) entre o título atual e o próximo.
  static double progressToNext(int drinks, int maxGoal) {
    final reqs = thresholdsFor(maxGoal);
    var cur = 0;
    for (var i = 0; i < reqs.length; i++) {
      if (drinks >= reqs[i]) cur = i;
    }
    final curReq = reqs[cur];
    final nxt = nextTier(drinks, maxGoal);
    if (nxt == null) return 1;
    final nxtReq = reqs[tiers.indexOf(nxt)];
    if (nxtReq == curReq) return 1;
    return ((drinks - curReq) / (nxtReq - curReq)).clamp(0.0, 1.0);
  }
}