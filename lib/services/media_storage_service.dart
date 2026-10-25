import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class MediaStorageService {
  MediaStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadProductPhoto({
    required String productId,
    required XFile file,
  }) =>
      _uploadPhoto(
        folder: 'products',
        recordId: productId,
        file: file,
        label: 'Product',
      );

  Future<String> _uploadPhoto({
    required String folder,
    required String recordId,
    required XFile file,
    required String label,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('An authenticated owner is required.');
    }

    final normalizedId = recordId.trim();
    if (normalizedId.isEmpty || normalizedId.contains('/')) {
      throw ArgumentError('A valid record id is required.');
    }

    final extension = _extension(file.name);
    final reference = _storage.ref(
      'users/${user.uid}/$folder/$normalizedId.$extension',
    );
    final metadata = SettableMetadata(
      contentType: _contentType(extension),
      customMetadata: {
        'ownerId': user.uid,
        'recordId': normalizedId,
      },
    );
    final byteLength = await file.length();
    if (byteLength > 5 * 1024 * 1024) {
      throw StateError('$label photos must be smaller than 5 MB.');
    }
    final bytes = await file.readAsBytes();
    await reference.putData(bytes, metadata);
    return reference.getDownloadURL();
  }

  Future<void> deleteOwnedPhoto(String? downloadUrl) async {
    if (downloadUrl == null || downloadUrl.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('An authenticated owner is required.');
    }

    final reference = _storage.refFromURL(downloadUrl);
    if (!reference.fullPath.startsWith('users/${user.uid}/')) {
      throw StateError('The photo does not belong to the authenticated owner.');
    }
    await reference.delete();
  }

  String _extension(String name) {
    final dot = name.lastIndexOf('.');
    final extension = dot >= 0 ? name.substring(dot + 1).toLowerCase() : 'jpg';
    return const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)
        ? extension
        : 'jpg';
  }

  String _contentType(String extension) => switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
}
