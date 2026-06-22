/// SQLite open + schema for Reframe.
///
/// Two tables: `capsules` (one row per capsule) and `frames` (the ordered
/// before/after photos). Photos themselves are stored as encrypted files in
/// the app documents dir (see [PhotoVault]); the DB only holds metadata.
library;

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'reframe.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE capsules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            created_at TEXT NOT NULL,
            unlock_at TEXT,
            finalized INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE frames (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            capsule_id INTEGER NOT NULL,
            kind TEXT NOT NULL,
            file_name TEXT NOT NULL,
            captured_at TEXT NOT NULL,
            FOREIGN KEY (capsule_id) REFERENCES capsules(id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_frames_capsule ON frames(capsule_id)');
      },
    );
    return _db!;
  }
}