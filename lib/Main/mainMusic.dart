import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../Database/app_database.dart';

const String _musicIconSvg = '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 3V14.55C11.38 14.21 10.66 14 9.9 14C7.7 14 5.9 15.8 5.9 18C5.9 20.2 7.7 22 9.9 22C12.1 22 13.9 20.2 13.9 18V7H17V3H12Z" fill="currentColor"/>
</svg>''';

class MusicTab extends StatefulWidget {
  const MusicTab({super.key});

  @override
  State<MusicTab> createState() => _MusicTabState();
}

class _MusicTabState extends State<MusicTab> {
  late Future<List<Map<String, Object?>>> _playlistsFuture;

  @override
  void initState() {
    super.initState();
    _playlistsFuture = AppDatabase.instance.getPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Музыка',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Общий список песен и подборок',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<Map<String, Object?>>>(
              future: _playlistsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF66DEDD)));
                }

                final playlists = snapshot.data ?? [];

                return FutureBuilder<List<_SongItemData>>(
                  future: _loadSongs(playlists),
                  builder: (context, songsSnapshot) {
                    if (!songsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF66DEDD)));
                    }

                    final songs = songsSnapshot.data ?? [];
                    return ListView.separated(
                      itemCount: songs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1624),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: song.cover,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: SvgPicture.string(
                                    _musicIconSvg,
                                    width: 24,
                                    height: 24,
                                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song.title,
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(song.artist, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.more_horiz, color: Colors.white54),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<List<_SongItemData>> _loadSongs(List<Map<String, Object?>> playlists) async {
  final songs = <_SongItemData>[];
  for (final playlist in playlists) {
    final playlistId = playlist['id'] as int;
    final tracks = await AppDatabase.instance.getPlaylistTracks(playlistId);
    for (final track in tracks) {
      songs.add(
        _SongItemData(
          title: track['title'] as String? ?? 'Без названия',
          artist: track['artist'] as String? ?? 'Неизвестно',
          cover: _parseColor(track['cover'] as String? ?? '#1B3A6A'),
        ),
      );
    }
  }
  return songs;
}

Color _parseColor(String value) {
  final normalized = value.replaceFirst('#', '');
  if (normalized.length == 6) {
    return Color(int.parse('0xFF$normalized'));
  }
  return const Color(0xFF1B3A6A);
}

class _SongItemData {
  final String title;
  final String artist;
  final Color cover;

  const _SongItemData({required this.title, required this.artist, required this.cover});
}
