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
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('An authenticated owner is required.');
    }

    final extension = _extension(file.name);
    final reference = _storage.ref(
      'users/${user.uid}/products/$productId.$extension',
    );
    final metadata = SettableMetadata(
      contentType: _contentType(extension),
      customMetadata: {'ownerId': user.uid},
    );
    final bytes = await file.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      throw StateError('Product photos must be smaller than 5 MB.');
    }
    await reference.putData(bytes, metadata);
    return reference.getDownloadURL();
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
