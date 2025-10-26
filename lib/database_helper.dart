import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('baby_monitor.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL
    );
    ''');

    await db.execute('''
    CREATE TABLE baby_profiles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      age INTEGER,
      gender TEXT,
      weight REAL,
      height REAL
    );
    ''');

    await db.execute('''
    CREATE TABLE settings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      theme TEXT
    );
    ''');

    await db.execute('''
    CREATE TABLE readings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT,
      value REAL,
      timestamp INTEGER
    );
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        theme TEXT
      );
      ''');
      await db.execute('''
      CREATE TABLE IF NOT EXISTS readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT,
        value REAL,
        timestamp INTEGER
      );
      ''');
    }
  }

  // Users
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    return await db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUser(String email, String password) async {
    final db = await instance.database;
    final result = await db.query('users', where: 'email = ? AND password = ?', whereArgs: [email, password]);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getUsersAll() async {
    final db = await instance.database;
    return await db.query('users');
  }

  // Baby profiles
  Future<int> insertBabyProfile(Map<String, dynamic> profile) async {
    final db = await instance.database;
    return await db.insert('baby_profiles', profile, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getBabyProfiles() async {
    final db = await instance.database;
    return await db.query('baby_profiles');
  }

  // Settings
  Future<Map<String, dynamic>?> getSettings() async {
    final db = await instance.database;
    final res = await db.query('settings', limit: 1);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<int> setSettings(Map<String, dynamic> s) async {
    final db = await instance.database;
    await db.delete('settings');
    return await db.insert('settings', s, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Readings (for tips)
  Future<int> insertReading(String type, double value) async {
    final db = await instance.database;
    return await db.insert('readings', {'type': type, 'value': value, 'timestamp': DateTime.now().millisecondsSinceEpoch});
  }

  Future<List<double>> getRecentTemps({int limit = 30}) async {
    final db = await instance.database;
    final res = await db.query('readings', where: "type = ?", whereArgs: ['temp'], orderBy: 'timestamp DESC', limit: limit);
    return res.map((e) => (e['value'] as num).toDouble()).toList();
  }

  Future<List<double>> getRecentNoises({int limit = 30}) async {
    final db = await instance.database;
    final res = await db.query('readings', where: "type = ?", whereArgs: ['noise'], orderBy: 'timestamp DESC', limit: limit);
    return res.map((e) => (e['value'] as num).toDouble()).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

