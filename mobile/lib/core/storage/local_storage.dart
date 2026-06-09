import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalStorage {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('rockydex.db');
    return _database!;
  }

  static Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  static Future<void> _createDB(Database db, int version) async {
    // Create local favorites table
    await db.execute('''
      CREATE TABLE local_favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        slug TEXT UNIQUE,
        name TEXT,
        thumb_url TEXT,
        created_at TEXT
      )
    ''');

    // Create local history table
    await db.execute('''
      CREATE TABLE local_histories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        comic_slug TEXT UNIQUE,
        comic_name TEXT,
        comic_thumb TEXT,
        chapter_slug TEXT,
        chapter_name TEXT,
        progress_percent INTEGER,
        page_number INTEGER DEFAULT 1,
        last_read_at TEXT
      )
    ''');
  }

  static Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE local_histories ADD COLUMN page_number INTEGER DEFAULT 1');
    }
  }

  // Favorites Helpers
  static Future<void> insertFavorite(Map<String, dynamic> fav) async {
    final db = await database;
    await db.insert(
      'local_favorites',
      fav,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteFavorite(String slug) async {
    final db = await database;
    await db.delete(
      'local_favorites',
      where: 'slug = ?',
      whereArgs: [slug],
    );
  }

  static Future<void> clearFavorites() async {
    final db = await database;
    await db.delete('local_favorites');
  }

  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final db = await database;
    return await db.query('local_favorites', orderBy: 'created_at DESC');
  }

  static Future<bool> isFavorite(String slug) async {
    final db = await database;
    final maps = await db.query(
      'local_favorites',
      where: 'slug = ?',
      whereArgs: [slug],
    );
    return maps.isNotEmpty;
  }

  // History Helpers
  static Future<void> saveHistory(Map<String, dynamic> hist) async {
    final db = await database;
    await db.insert(
      'local_histories',
      hist,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteHistory(String slug) async {
    final db = await database;
    await db.delete(
      'local_histories',
      where: 'comic_slug = ?',
      whereArgs: [slug],
    );
  }

  static Future<List<Map<String, dynamic>>> getHistoryList() async {
    final db = await database;
    return await db.query('local_histories', orderBy: 'last_read_at DESC');
  }

  static Future<Map<String, dynamic>?> getComicHistory(String slug) async {
    final db = await database;
    final maps = await db.query(
      'local_histories',
      where: 'comic_slug = ?',
      whereArgs: [slug],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  static Future<void> clearHistory() async {
    final db = await database;
    await db.delete('local_histories');
  }
}
