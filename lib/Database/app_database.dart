import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'oncast.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE playlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        subtitle TEXT,
        accent TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlistId INTEGER NOT NULL,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        cover TEXT NOT NULL,
        FOREIGN KEY (playlistId) REFERENCES playlists(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE calendar_assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        playlistId INTEGER,
        note TEXT
      )
    ''');

    await db.insert('playlists', {
      'title': 'Ночной вайб',
      'subtitle': '45 треков',
      'accent': '#5C7CFA',
      'createdAt': DateTime.now().toIso8601String(),
    });

    await db.insert('playlists', {
      'title': 'Тренировка',
      'subtitle': '28 треков',
      'accent': '#00C3C7',
      'createdAt': DateTime.now().toIso8601String(),
    });

    await db.insert('playlists', {
      'title': 'Кофе и работа',
      'subtitle': '33 трека',
      'accent': '#FF7A59',
      'createdAt': DateTime.now().toIso8601String(),
    });

    await db.insert('playlists', {
      'title': 'Отдых',
      'subtitle': '19 треков',
      'accent': '#8E44AD',
      'createdAt': DateTime.now().toIso8601String(),
    });

    await db.insert('tracks', {
      'playlistId': 1,
      'title': 'Midnight City',
      'artist': 'M83',
      'cover': '#1B3A6A',
    });

    await db.insert('tracks', {
      'playlistId': 1,
      'title': 'Blue Monday',
      'artist': 'New Order',
      'cover': '#00C3C7',
    });

    await db.insert('tracks', {
      'playlistId': 2,
      'title': 'Stay',
      'artist': 'The Kid LAROI',
      'cover': '#FF7A59',
    });
  }

  Future<List<Map<String, Object?>>> getPlaylists() async {
    final db = await database;
    return db.query('playlists', orderBy: 'id ASC');
  }

  Future<List<Map<String, Object?>>> getPlaylistTracks(int playlistId) async {
    final db = await database;
    return db.query(
      'tracks',
      where: 'playlistId = ?',
      whereArgs: [playlistId],
      orderBy: 'id ASC',
    );
  }

  Future<int> insertPlaylist(Map<String, Object?> playlist) async {
    final db = await database;
    return db.insert('playlists', playlist);
  }

  Future<int> insertTrack(Map<String, Object?> track) async {
    final db = await database;
    return db.insert('tracks', track);
  }

  Future<int> deleteTrack(int trackId) async {
    final db = await database;
    return db.delete(
      'tracks',
      where: 'id = ?',
      whereArgs: [trackId],
    );
  }

  Future<Map<String, Object?>?> getAssignmentByDate(String date) async {
    final db = await database;
    final result = await db.query(
      'calendar_assignments',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    return result.isEmpty ? null : result.first;
  }

  Future<List<Map<String, Object?>>> getAssignmentsByDatePrefix(String datePrefix) async {
    final db = await database;
    return db.query(
      'calendar_assignments',
      where: 'date LIKE ?',
      whereArgs: ['$datePrefix%'],
      orderBy: 'date ASC',
    );
  }

  Future<int> saveAssignment(String date, int? playlistId, {String? note}) async {
    final db = await database;
    final existing = await getAssignmentByDate(date);
    if (existing == null) {
      return db.insert('calendar_assignments', {
        'date': date,
        'playlistId': playlistId,
        'note': note,
      });
    }
    return db.update(
      'calendar_assignments',
      {
        'playlistId': playlistId,
        'note': note,
      },
      where: 'date = ?',
      whereArgs: [date],
    );
  }
}
