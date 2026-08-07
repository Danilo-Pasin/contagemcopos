import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/storage_keys.dart';

/// Serviço de identidade local — gerencia o usuário anônimo e o perfil salvo.
///
/// Como o app NÃO tem login, geramos:
///  - Uma sessão anônima do Supabase (auth.uid) para RLS.
///  - Um perfil local (nome + foto) persistido no navegador.
///  - Um mapa local groupCode -> participantId para reconhecimento automático.
class IdentityService {
  IdentityService(this._prefs, this._client);

  final SharedPreferences _prefs;
  final SupabaseClient _client;

  String? get anonId => _prefs.getString(StorageKeys.currentAnonId);

  String get savedName => _prefs.getString(StorageKeys.currentName) ?? '';

  String? get accountId => _prefs.getString(StorageKeys.currentAccountId);

  String? get savedPhoto => _prefs.getString(StorageKeys.currentPhoto);

  bool get hasProfile => savedName.trim().isNotEmpty;

  /// Garante que existe uma sessão anônima ativa.
  /// Restaura a existente (persistida pelo Supabase) ou cria nova.
  Future<String> ensureAnonSession() async {
    final existing = _client.auth.currentSession;
    if (existing != null && existing.user != null) {
      final id = existing.user!.id;
      await _prefs.setString(StorageKeys.currentAnonId, id);
      return id;
    }

    final res = await _client.auth.signInAnonymously();
    final id = res.user?.id;
    if (id == null) throw Exception('Falha ao criar sessão anônima');
    await _prefs.setString(StorageKeys.currentAnonId, id);
    return id;
  }

  /// Salva o perfil local (nome + foto opcional) e o id de conta (login nome+senha).
  Future<void> saveProfile({
    required String name,
    String? photoUrl,
    String? accountId,
  }) async {
    await _prefs.setString(StorageKeys.currentName, name.trim());
    if (accountId != null) {
      await _prefs.setString(StorageKeys.currentAccountId, accountId);
    }
    if (photoUrl != null) {
      await _prefs.setString(StorageKeys.currentPhoto, photoUrl);
    }
  }

  /// Registra qual participante deste dispositivo corresponde a cada grupo.
  Future<void> rememberMember(String groupCode, String participantId) async {
    final map = _memberMap;
    map[groupCode] = participantId;
    await _prefs.setString(StorageKeys.memberMap, jsonEncode(map));
  }

  String? memberOf(String groupCode) => _memberMap[groupCode];

  Map<String, String> get _memberMap {
    final raw = _prefs.getString(StorageKeys.memberMap);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v.toString()));
  }

  /// Lista de códigos de grupo conhecidos neste dispositivo.
  List<String> get knownGroups => _memberMap.keys.toList();
}
