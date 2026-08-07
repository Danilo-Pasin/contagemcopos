import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Serviço de upload para o Supabase Storage (avatars e fotos de bebida).
class AppStorageService {
  AppStorageService(this._client);
  final SupabaseClient _client;
  static const _bucketAvatars = 'avatars';
  static const _bucketDrinks = 'drinks';

  /// Faz upload de um avatar e retorna a URL pública.
  Future<String> uploadAvatar(String userId, XFile file) async {
    final ext = file.name.split('.').last.toLowerCase();
    final path = '$userId/${const Uuid().v4()}.$ext';
    final bytes = await file.readAsBytes();
    await _client.storage.from(_bucketAvatars).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}',
            upsert: false,
          ),
        );
    return _client.storage.from(_bucketAvatars).getPublicUrl(path);
  }

  /// Faz upload de uma foto de bebida/feed e retorna a URL pública.
  Future<String> uploadDrinkPhoto(String userId, XFile file) async {
    final ext = file.name.split('.').last.toLowerCase();
    final path = '$userId/${const Uuid().v4()}.$ext';
    final bytes = await file.readAsBytes();
    await _client.storage.from(_bucketDrinks).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}',
            upsert: false,
          ),
        );
    return _client.storage.from(_bucketDrinks).getPublicUrl(path);
  }
}
