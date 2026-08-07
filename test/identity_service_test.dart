import 'package:contagem/core/constants/storage_keys.dart';
import 'package:contagem/data/services/identity_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late IdentityService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Construir o client não faz chamadas de rede; usado só para memória_local.
    final SupabaseClient client = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
    );
    return Future.sync(() async {
      final prefs = await SharedPreferences.getInstance();
      service = IdentityService(prefs, client);
    });
  });

  group('perfil local (sem rede)', () {
    test('estado padrão vazio', () {
      expect(service.savedName, '');
      expect(service.hasProfile, isFalse);
      expect(service.anonId, isNull);
      expect(service.accountId, isNull);
      expect(service.knownGroups, isEmpty);
    });

    test('saveProfile guarda nome e accountId', () async {
      await service.saveProfile(name: '  João  ', accountId: 'acc-1');
      expect(service.savedName, 'João'); // trima
      expect(service.accountId, 'acc-1');
      expect(service.hasProfile, isTrue);
    });

    test('accountId só muda se fornecido', () async {
      await service.saveProfile(name: 'A');
      expect(service.accountId, isNull);
      await service.saveProfile(name: 'A');
      expect(service.accountId, isNull);
    });
  });

  group('rememberMember/memberOf', () {
    test('registra e recupera por código de grupo', () async {
      await service.rememberMember('ABC123', 'part-1');
      expect(service.memberOf('ABC123'), 'part-1');
      expect(service.memberOf('ZZZ'), isNull);
      expect(service.knownGroups, ['ABC123']);
    });

    test('multiplica grupos no mapa', () async {
      await service.rememberMember('AAA', 'pA');
      await service.rememberMember('BBB', 'pB');
      expect(service.knownGroups, containsAll(['AAA', 'BBB']));
      expect(service.memberOf('AAA'), 'pA');
      expect(service.memberOf('BBB'), 'pB');
    });

    test('storage usa a chave corrente do app', () async {
      await service.rememberMember('X1', 'pX');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.memberMap), isNotEmpty);
    });
  });
}