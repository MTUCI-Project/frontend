import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../Database/app_database.dart';

class MusicTab extends StatefulWidget {
  const MusicTab({super.key, required this.onPlayQueue});

  final void Function(List<Map<String, Object?>> queue, {required int startIndex}) onPlayQueue;

  @override
  State<MusicTab> createState() => _MusicTabState();
}

class _MusicTabState extends State<MusicTab> {
  late Future<List<_SongItemData>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _songsFuture = _loadSongs();
  }

  void _refresh() {
    setState(() {
      _songsFuture = _loadSongs();
    });
  }

  Future<void> _pickAndAddSongFromStorage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'wav'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final parsedName = _parseTrackName(
      p.basenameWithoutExtension(file.name).trim(),
    );

    final playlists = await AppDatabase.instance.getPlaylists();

    final playlistId = playlists.isEmpty
        ? await AppDatabase.instance.insertPlaylist({
            'title': 'Импорт',
            'subtitle': 'Импорт',
            'accent': '#66DEDD',
            'createdAt': DateTime.now().toIso8601String(),
          })
        : playlists.first['id'] as int;

    await AppDatabase.instance.insertTrack({
      'playlistId': playlistId,
      'title': parsedName.title.isEmpty ? 'Новая песня' : parsedName.title,
      'artist': parsedName.artist.isEmpty ? 'Из загрузок' : parsedName.artist,
      'cover': '#1B3A6A',
      'filePath': file.path,
    });

    if (!mounted) return;
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            /// HEADER
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Музыка",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Список треков",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: _pickAndAddSongFromStorage,
                  icon: const Icon(
                    Icons.add,
                    color: Color(0xFF66DEDD),
                    size: 28,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// TABLE HEADER
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white24),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Text(
                      "Название",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      "Исполнитель",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            /// LIST
            Expanded(
              child: FutureBuilder<List<_SongItemData>>(
                future: _songsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF66DEDD),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        "Ошибка загрузки",
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final songs = snapshot.data ?? [];

                  if (songs.isEmpty) {
                    return const Center(
                      child: Text(
                        "Нет песен",
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];

                      return GestureDetector(
                        onTap: () => widget.onPlayQueue(
                          songs.map((song) => {
                            'id': song.trackId,
                            'playlistId': song.playlistId,
                            'title': song.title,
                            'artist': song.artist,
                            'cover': song.cover,
                            'filePath': song.filePath,
                          }).toList(),
                          startIndex: index,
                        ),
                        child: Dismissible(
                          key: ValueKey(song.title + index.toString()),
                          direction: DismissDirection.endToStart,

                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),

                        onDismissed: (_) async {
                          final playlists =
                              await AppDatabase.instance.getPlaylists();

                          if (playlists.isEmpty) return;

                          final playlistId =
                              playlists.first['id'] as int;

                          final tracks =
                              await AppDatabase.instance.getPlaylistTracks(
                            playlistId,
                          );

                          final target = tracks.firstWhere(
                            (t) =>
                                t['title'] == song.title &&
                                t['artist'] == song.artist,
                            orElse: () => {},
                          );

                          if (target.isNotEmpty) {
                            await AppDatabase.instance.deleteTrack(
                              target['id'] as int,
                            );
                          }

                          _refresh();
                        },

                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: Text(
                                      song.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      song.artist,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(
                              color: Colors.white10,
                              height: 1,
                            ),
                          ],
                        ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

({String title, String artist}) _parseTrackName(String input) {
  final normalized = input
      .replaceAll(RegExp(r'[_]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  final match = RegExp(
    r'^(?<artist>.+?)\s*(?:-|–|—|:|\|)\s*(?<title>.+)$',
    caseSensitive: false,
  ).firstMatch(normalized);

  if (match != null) {
    final artist = match.namedGroup('artist')?.trim() ?? '';
    final title = match.namedGroup('title')?.trim() ?? '';
    if (artist.isNotEmpty && title.isNotEmpty) {
      return (title: title, artist: artist);
    }
  }

  return (title: normalized, artist: 'Из загрузок');
}

/// LOAD DATA
Future<List<_SongItemData>> _loadSongs() async {
  final playlists = await AppDatabase.instance.getPlaylists();

  final result = <_SongItemData>[];

  for (final p in playlists) {
    final tracks =
        await AppDatabase.instance.getPlaylistTracks(
      p['id'] as int,
    );

    for (final t in tracks) {
      result.add(
        _SongItemData(
          trackId: t['id'] as int?,
          playlistId: p['id'] as int?,
          title: (t['title'] as String?) ?? 'No title',
          artist: (t['artist'] as String?) ?? 'Unknown',
          cover: (t['cover'] as String?) ?? '#1B3A6A',
          filePath: t['filePath'] as String?,
        ),
      );
    }
  }

  return result;
}

/// MODEL
class _SongItemData {
  final String title;
  final String artist;

  _SongItemData({
    required this.title,
    required this.artist,
  });
}