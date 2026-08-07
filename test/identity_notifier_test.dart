import 'package:contagem/data/services/identity_service.dart';
import 'package:contagem/presentation/providers/identity_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fake que nunca toca a rede: retorna id fixo (ou lança, quando configurado).
class _FakeIdentityService extends IdentityService {
  _FakeIdentityService(super.prefs, super.client, {this.fail = false});

  final bool fail;

  @override
  Future<String> ensureAnonSession() async {
    if (fail) throw Exception('rede indisponível');
    return 'anon-fake';
  }
}

Future<_FakeIdentityService> _service({bool fail = false}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final client = SupabaseClient('https://example.supabase.co', 'test-anon-key');
  return _FakeIdentityService(prefs, client, fail: fail);
}

void main() {
  group('IdentityState', () {
    test('hasProfile ignora espaços', () {
      expect(const IdentityState().hasProfile, isFalse);
      expect(const IdentityState(savedName: '  ').hasProfile, isFalse);
      expect(const IdentityState(savedName: 'Zé').hasProfile, isTrue);
      expect(const IdentityState(savedName: '  Zé  ').hasProfile, isTrue);
    });

    test('copyWith preserva campos não alterados e troca error', () {
      const s = IdentityState(ready: true, anonId: 'a1', savedName: 'Zé');
      final updated = s.copyWith(ready: false, savedName: 'Ana');
      expect(updated.ready, isFalse);
      expect(updated.anonId, 'a1');
      expect(updated.savedName, 'Ana');

      final withError = s.copyWith(error: 'boom');
      expect(withError.error, 'boom');
      expect(withError.anonId, 'a1');
    });
  });

  group('IdentityNotifier', () {
    test('init preenche estado com anonId e perfil salvo', () async {
      final svc = await _service();
      final notifier = IdentityNotifier(svc);
      await Future<void>.delayed(Duration.zero); // deixa _init() rodar

      expect(notifier.state.ready, isTrue);
      expect(notifier.state.anonId, 'anon-fake');
      expect(notifier.state.error, isNull);
    });

    test('init falha => ready com error', () async {
      final svc = await _service(fail: true);
      final notifier = IdentityNotifier(svc);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.ready, isTrue);
      expect(notifier.state.error, isNotNull);
    });

    test('saveProfile atualiza nome/accountId no estado', () async {
      final svc = await _service();
      final notifier = IdentityNotifier(svc);
      await Future<void>.delayed(Duration.zero);

      await notifier.saveProfile(name: '  Zé  ', accountId: 'acc-1');
      expect(notifier.state.savedName, 'Zé');
      expect(notifier.state.accountId, 'acc-1');
      expect(notifier.state.hasProfile, isTrue);
    });

    test('rememberMember registra e expõe knownGroups', () async {
      final svc = await _service();
      final notifier = IdentityNotifier(svc);
      await Future<void>.delayed(Duration.zero);

      await notifier.rememberMember('ABC123', 'part-1');
      expect(notifier.memberOf('ABC123'), 'part-1');
      expect(notifier.knownGroups, contains('ABC123'));
      expect(notifier.state.knownGroups, contains('ABC123'));
    });

    test('ensureReady retorna anonId já existente sem nova chamada', () async {
      final svc = await _service();
      final notifier = IdentityNotifier(svc);
      await Future<void>.delayed(Duration.zero);

      final id = await notifier.ensureReady();
      expect(id, 'anon-fake');
      expect(notifier.state.anonId, 'anon-fake');
    });
  });
}