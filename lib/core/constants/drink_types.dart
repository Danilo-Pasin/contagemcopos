/// Tipos de bebida registráveis no app.
///
/// Aparecem no popup opcional ao registrar uma bebida ("+1 BEBIDA") e também
/// no dashboard de estatísticas ("Tipos de bebidas"). Se o usuário pular o
/// popup, a bebida fica sem tipo (null) e só conta na métrica total.
class DrinkTypeDef {
  final String id;
  final String emoji;
  final String label;

  const DrinkTypeDef(this.id, this.emoji, this.label);
}

const List<DrinkTypeDef> kDrinkTypes = [
  DrinkTypeDef('cerveja', '🍺', 'Cerveja'),
  DrinkTypeDef('longneck', '🍾', 'Long Neck'),
  DrinkTypeDef('vinho', '🍷', 'Vinho'),
  DrinkTypeDef('espumante', '🥂', 'Espumante'),
  DrinkTypeDef('destilado', '🥃', 'Destilado'),
  DrinkTypeDef('drink', '🍹', 'Drinque'),
  DrinkTypeDef('energetico', '⚡', 'Energético'),
  DrinkTypeDef('sem_alcool', '🥤', 'Sem álcool'),
  DrinkTypeDef('outro', '🧃', 'Outro'),
];

/// Resolve emojis/label de um tipo salvo; retorna null se desconhecido.
DrinkTypeDef? drinkTypeById(String? id) {
  if (id == null) return null;
  for (final t in kDrinkTypes) {
    if (t.id == id) return t;
  }
  return null;
}