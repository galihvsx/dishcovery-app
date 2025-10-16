import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> uploadImage(String imagePath, {String? folder}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final file = File(imagePath);
      if (!file.existsSync()) return null;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${user.uid}_$timestamp${path.extension(imagePath)}';

      final storagePath = folder != null
          ? '$folder/${user.uid}/$fileName'
          : 'scans/${user.uid}/$fileName';

      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(file);

      final snapshot = await uploadTask;

      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<String?> uploadImageBytes(
    List<int> imageBytes, {
    String? folder,
    String? extension = '.jpg',
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${user.uid}_$timestamp$extension';

      final storagePath = folder != null
          ? '$folder/${user.uid}/$fileName'
          : 'scans/${user.uid}/$fileName';

      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putData(
        Uint8List.fromList(imageBytes),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;

      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image bytes: $e');
      return null;
    }
  }

  Future<bool> deleteImage(String imageUrl) async {
    try {
      if (!imageUrl.contains('firebasestorage.googleapis.com')) {
        return true;
      }

      final ref = _storage.refFromURL(imageUrl);

      await ref.delete();

      print('Image deleted successfully: $imageUrl');
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  Future<bool> deleteUserImages() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final ref = _storage.ref().child('scans/${user.uid}');
      final result = await ref.listAll();

      for (final fileRef in result.items) {
        await fileRef.delete();
      }

      print('All user images deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting user images: $e');
      return false;
    }
  }

  Future<int> getUserStorageUsage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      int totalSize = 0;

      final ref = _storage.ref().child('scans/${user.uid}');
      final result = await ref.listAll();

      for (final fileRef in result.items) {
        final metadata = await fileRef.getMetadata();
        totalSize += metadata.size ?? 0;
      }

      return totalSize;
    } catch (e) {
      print('Error getting storage usage: $e');
      return 0;
    }
  }

  bool isValidImageFile(String filePath) {
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final extension = path.extension(filePath).toLowerCase();
    return validExtensions.contains(extension);
  }

  Future<File?> compressImage(File imageFile, {int quality = 85}) async {
    return imageFile;
  }
}
