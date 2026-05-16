import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> uploadFile({
    required String path,
    required String id,
    required Uint8List fileBytes,
  }) async {
    // Note: The bucket (e.g., 'trade-licenses') must be created in Supabase dashboard
    final fullPath = '$path/$id';
    await _supabase.storage.from('paikari-files').uploadBinary(
      fullPath,
      fileBytes,
      fileOptions: const FileOptions(upsert: true),
    );
    
    return _supabase.storage.from('paikari-files').getPublicUrl(fullPath);
  }
}

final storageRepositoryProvider = Provider((ref) => StorageRepository());
