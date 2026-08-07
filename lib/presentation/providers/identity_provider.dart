import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/identity_service.dart';
import 'core_providers.dart';

/// Estado da inicialização de identidade anônima.
class IdentityState {
  final bool ready;
  final String? anonId;
  final String savedName;
  final String? accountId;
  final String? savedPhoto;
  final List<String> knownGroups;
  final Object? error;

  const IdentityState({
    this.ready = false,
    this.anonId,
    this.savedName = '',
    this.accountId,
    this.savedPhoto,
    this.knownGroups = const [],
    this.error,
  });

  bool get hasProfile => savedName.trim().isNotEmpty;

  IdentityState copyWith({
    bool? ready,
    String? anonId,
    String? savedName,
    String? accountId,
    String? savedPhoto,
    List<String>? knownGroups,
    Object? error,
  }) =>
      IdentityState(
        ready: ready ?? this.ready,
        anonId: anonId ?? this.anonId,
        savedName: savedName ?? this.savedName,
        accountId: accountId ?? this.accountId,
        savedPhoto: savedPhoto ?? this.savedPhoto,
        knownGroups: knownGroups ?? this.knownGroups,
        error: error,
      );
}

class IdentityNotifier extends StateNotifier<IdentityState> {
  IdentityNotifier(this._service) : super(const IdentityState()) {
    _init();
  }

  final IdentityService _service;

  Future<void> _init() async {
    try {
      debugPrint('[Identity] iniciando sessão anônima...');
      final anonId = await _service.ensureAnonSession();
      debugPrint('[Identity] sessão OK: $anonId');
      state = IdentityState(
        ready: true,
        anonId: anonId,
        savedName: _service.savedName,
        accountId: _service.accountId,
        savedPhoto: _service.savedPhoto,
        knownGroups: _service.knownGroups,
      );
    } catch (e) {
      debugPrint('[Identity] ERRO: $e');
      state = IdentityState(ready: true, error: e);
    }
  }

  /// Garante que a sessão anônima está pronta (com retry).
  /// Retorna o anonId. Útil para chamar antes de operações críticas.
  Future<String> ensureReady() async {
    if (state.anonId != null) return state.anonId!;
    try {
      final anonId = await _service.ensureAnonSession();
      state = IdentityState(
        ready: true,
        anonId: anonId,
        savedName: _service.savedName,
        accountId: _service.accountId,
        savedPhoto: _service.savedPhoto,
        knownGroups: _service.knownGroups,
      );
      return anonId;
    } catch (e) {
      debugPrint('[Identity] ensureReady ERRO: $e');
      rethrow;
    }
  }

  /// Salva o perfil local (nome, foto e id de conta quando houver).
  Future<void> saveProfile({
    required String name,
    String? photoUrl,
    String? accountId,
  }) async {
    await _service.saveProfile(
      name: name,
      photoUrl: photoUrl,
      accountId: accountId,
    );
    state = state.copyWith(
      savedName: name,
      savedPhoto: photoUrl,
      accountId: accountId ?? state.accountId,
    );
  }

  /// Recupera o participantId salvo para um grupo.
  String? memberOf(String groupCode) => _service.memberOf(groupCode);

  Future<void> rememberMember(String groupCode, String participantId) async {
    await _service.rememberMember(groupCode, participantId);
    state = state.copyWith(knownGroups: _service.knownGroups);
  }

  List<String> get knownGroups => _service.knownGroups;
}

final identityProvider =
    StateNotifierProvider<IdentityNotifier, IdentityState>((ref) {
  return IdentityNotifier(ref.watch(identityServiceProvider));
});
