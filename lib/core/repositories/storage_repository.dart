import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile({
    required String path,
    required String id,
    required Uint8List fileBytes,
  }) async {
    final ref = _storage.ref().child(path).child(id);
    UploadTask uploadTask = ref.putData(fileBytes);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}

final storageRepositoryProvider = Provider((ref) => StorageRepository());
