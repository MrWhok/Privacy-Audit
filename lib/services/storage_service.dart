import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;

  static String get _uid =>
      FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

  static Future<String?> uploadScreenshot(File imageFile, String appName) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${appName.replaceAll(' ', '_')}_$timestamp.jpg';
      final ref = _storage.ref().child('screenshots/$_uid/$fileName');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  static Future<void> deleteScreenshot(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }
}
