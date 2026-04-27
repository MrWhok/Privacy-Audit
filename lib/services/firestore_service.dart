import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_entry.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static String get _uid =>
      FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

  static CollectionReference get _appsRef =>
      _db.collection('users').doc(_uid).collection('apps');

  static Future<void> saveApp(AppEntry entry) async {
    try {
      await _appsRef.doc(entry.id.toString()).set({
        'id': entry.id,
        'name': entry.name,
        'category': entry.category,
        'risk_level': entry.riskLevel,
        'notes': entry.notes,
        'screenshot_url': entry.screenshotUrl,
        'last_audited': entry.lastAudited,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
    }
  }

  static Future<void> deleteApp(int appId) async {
    await _appsRef.doc(appId.toString()).delete();
  }

  static Future<List<Map<String, dynamic>>> getApps() async {
    try {
      final snapshot = await _appsRef
          .orderBy('updated_at', descending: true)
          .get();
      return snapshot.docs
          .map((d) => d.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }
}
