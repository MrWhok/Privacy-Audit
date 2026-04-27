import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/app_entry.dart';
import '../models/permission_item.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ppb_privacy_audit.db');
    return openDatabase(
      path,
      version: 2, 
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE apps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            risk_level TEXT NOT NULL,
            notes TEXT,
            screenshot_url TEXT,
            last_audited TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE permissions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            app_id INTEGER NOT NULL,
            perm_type TEXT NOT NULL,
            granted INTEGER NOT NULL DEFAULT 0,
            reason TEXT,
            FOREIGN KEY (app_id) REFERENCES apps (id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE apps ADD COLUMN user_id TEXT NOT NULL DEFAULT ""');
        }
      },
    );
  }


  static Future<int> insertApp(AppEntry entry, String userId) async {
    final db = await database;
    final map = entry.toMap()..remove('id');
    map['user_id'] = userId;
    return db.insert('apps', map);
  }

  static Future<List<AppEntry>> getAllApps(String userId) async {
    final db = await database;
    final maps = await db.query(
      'apps',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'last_audited DESC',
    );
    return maps.map((m) => AppEntry.fromMap(m)).toList();
  }

  static Future<AppEntry?> getApp(int id) async {
    final db = await database;
    final maps = await db.query('apps', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return AppEntry.fromMap(maps.first);
  }

  static Future<void> updateApp(AppEntry entry) async {
    final db = await database;
    await db.update('apps', entry.toMap(), where: 'id = ?', whereArgs: [entry.id]);
  }

  static Future<void> deleteApp(int id) async {
    final db = await database;
    await db.delete('apps', where: 'id = ?', whereArgs: [id]);
    await db.delete('permissions', where: 'app_id = ?', whereArgs: [id]);
  }


  static Future<void> insertPermissions(List<PermissionItem> perms) async {
    final db = await database;
    final batch = db.batch();
    for (final p in perms) {
      batch.insert('permissions', p.toMap()..remove('id'));
    }
    await batch.commit(noResult: true);
  }

  static Future<List<PermissionItem>> getPermissions(int appId) async {
    final db = await database;
    final maps = await db.query(
      'permissions',
      where: 'app_id = ?',
      whereArgs: [appId],
    );
    return maps.map((m) => PermissionItem.fromMap(m)).toList();
  }

  static Future<void> updatePermission(PermissionItem perm) async {
    final db = await database;
    await db.update('permissions', perm.toMap(),
        where: 'id = ?', whereArgs: [perm.id]);
  }

  static Future<void> deletePermissions(int appId) async {
    final db = await database;
    await db.delete('permissions', where: 'app_id = ?', whereArgs: [appId]);
  }


  static Future<Map<String, int>> getRiskCounts(String userId) async {
    final db = await database;
    final all = await db.query('apps', where: 'user_id = ?', whereArgs: [userId]);
    final counts = {'Critical': 0, 'High': 0, 'Medium': 0, 'Low': 0};
    for (final row in all) {
      final risk = row['risk_level'] as String;
      counts[risk] = (counts[risk] ?? 0) + 1;
    }
    return counts;
  }
}
