import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';
import '../../data/repositories/achievement_repository.dart';
import '../../data/repositories/drink_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/services/identity_service.dart';
import '../../data/services/storage_service.dart';

/// Cliente Supabase singleton.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// SharedPreferences singleton.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in main()');
});

/// Serviço de identidade local.
final identityServiceProvider = Provider<IdentityService>((ref) {
  return IdentityService(
    ref.watch(sharedPreferencesProvider),
    ref.watch(supabaseClientProvider),
  );
});

/// Serviço de storage.
final storageServiceProvider = Provider<AppStorageService>((ref) {
  return AppStorageService(ref.watch(supabaseClientProvider));
});

/// Repositórios.
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(ref.watch(supabaseClientProvider));
});

final drinkRepositoryProvider = Provider<DrinkRepository>((ref) {
  return DrinkRepository(ref.watch(supabaseClientProvider));
});

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepository(ref.watch(supabaseClientProvider));
});

/// Schema helper (para queries diretas).
final schemaProvider = Provider<String>((ref) => AppConfig.schema);

/// URL base pública para compartilhamento (QR/links).
///
/// No Web deriva a origem do host em execução — funciona em localhost e em
/// qualquer domínio de produção (Vercel/Netlify/etc.) sem reconfiguração.
/// Em plataformas não-web (mobile/desktop) usa o valor configurado como
/// fallback, pois `Uri.base` não reflete o host público.
final publicBaseUrlProvider = Provider<String>((ref) {
  if (kIsWeb) {
    final base = Uri.base;
    if (base.host.isNotEmpty) {
      final port = base.hasPort ? ':${base.port}' : '';
      return '${base.scheme}://${base.host}$port';
    }
  }
  return AppConfig.publicBaseUrl;
});
