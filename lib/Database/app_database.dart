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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE tracks ADD COLUMN filePath TEXT');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS player_state (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              sourceType TEXT NOT NULL,
              sourceId INTEGER,
              currentTrackId INTEGER,
              currentIndex INTEGER NOT NULL DEFAULT 0,
              isPlaying INTEGER NOT NULL DEFAULT 0,
              updatedAt TEXT NOT NULL
            )
          ''');
        }
      },
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
        filePath TEXT,
        FOREIGN KEY (playlistId) REFERENCES playlists(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE player_state (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        sourceType TEXT NOT NULL,
        sourceId INTEGER,
        currentTrackId INTEGER,
        currentIndex INTEGER NOT NULL DEFAULT 0,
        isPlaying INTEGER NOT NULL DEFAULT 0,
        updatedAt TEXT NOT NULL
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

  Future<List<Map<String, Object?>>> getAllTracks() async {
    final db = await database;
    return db.query('tracks', orderBy: 'id ASC');
  }

  Future<int> insertPlaylist(Map<String, Object?> playlist) async {
    final db = await database;
    return db.insert('playlists', playlist);
  }

  Future<int> deletePlaylist(int playlistId) async {
    final db = await database;
    return db.delete(
      'playlists',
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  Future<int> insertTrack(Map<String, Object?> track) async {
    final db = await database;
    return db.insert('tracks', track);
  }

  Future<Map<String, Object?>?> getPlayerState() async {
    final db = await database;
    final result = await db.query('player_state', where: 'id = ?', whereArgs: [1], limit: 1);
    return result.isEmpty ? null : result.first;
  }

  Future<int> savePlayerState({
    required String sourceType,
    int? sourceId,
    int? currentTrackId,
    required int currentIndex,
    required bool isPlaying,
  }) async {
    final db = await database;
    final existing = await getPlayerState();
    final payload = {
      'sourceType': sourceType,
      'sourceId': sourceId,
      'currentTrackId': currentTrackId,
      'currentIndex': currentIndex,
      'isPlaying': isPlaying ? 1 : 0,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (existing == null) {
      return db.insert('player_state', {'id': 1, ...payload});
    }

    return db.update(
      'player_state',
      payload,
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<int> clearPlayerState() async {
    final db = await database;
    return db.delete('player_state', where: 'id = ?', whereArgs: [1]);
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

  Future<int> deleteAssignment(String date) async {
  final db = await database;

  return db.delete(
    'calendar_assignments',
    where: 'date = ?',
    whereArgs: [date],
  );
}
}
