import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../Database/app_database.dart';
import 'mainMusic.dart';
import 'mainCalendar.dart';
import 'mainSettings.dart';
import 'player_controller.dart';

const String _discSvg = '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 2C6.48 2 2 6.48 2 12C2 17.52 6.48 22 12 22C17.52 22 22 17.52 22 12C22 6.48 17.52 2 12 2ZM12 16C9.79 16 8 14.21 8 12C8 9.79 9.79 8 12 8C14.21 8 16 9.79 16 12C16 14.21 14.21 16 12 16Z" fill="currentColor"/>
</svg>''';

const String _musicSvg = '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 3V14.55C11.38 14.21 10.66 14 9.9 14C7.7 14 5.9 15.8 5.9 18C5.9 20.2 7.7 22 9.9 22C12.1 22 13.9 20.2 13.9 18V7H17V3H12Z" fill="currentColor"/>
</svg>''';

const String _calendarSvg = '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M7 2H5V4H3C1.9 4 1 4.9 1 6V20C1 21.1 1.9 22 3 22H21C22.1 22 23 21.1 23 20V6C23 4.9 22.1 4 21 4H19V2H17V4H7V2ZM3 20V8H21V20H3Z" fill="currentColor"/>
</svg>''';

const String _userSvg = '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 12C14.76 12 17 9.76 17 7C17 4.24 14.76 2 12 2C9.24 2 7 4.24 7 7C7 9.76 9.24 12 12 12ZM12 14C8.13 14 5 17.13 5 21H19C19 17.13 15.87 14 12 14Z" fill="currentColor"/>
</svg>''';

final List<String> _playlistAccentPalette = [
  '#66DEDD',
  '#5C7CFA',
  '#FF6B6B',
  '#FFD166',
  '#9B5DE5',
  '#00C2A8',
  '#FF8FAB',
  '#4ECDC4',
  '#2EC4B6',
  '#FF7F50',
];

String _randomPlaylistAccent() {
  return _playlistAccentPalette[Random().nextInt(_playlistAccentPalette.length)];
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    PlayerController.instance.initialize();
    _pages = [
      const PlaylistsTab(),
      MusicTab(onPlayQueue: _startPlayback),
      const CalendarTab(),
      const SettingsTab(),
    ];
  }

  void _startPlayback(List<Map<String, Object?>> queue, {required int startIndex}) {
    PlayerController.instance.playQueue(
      queue: queue,
      startIndex: startIndex,
      sourceType: 'library',
      sourceId: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020912),
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(index: _selectedIndex, children: _pages),
            Positioned(
              left: 4,
              right: 4,
              bottom: 4,
              child: _MiniPlayerBar(
                onTap: () => setState(() {}),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF060D17),
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (value) => setState(() => _selectedIndex = value),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF060D17),
          selectedItemColor: const Color(0xFF66DEDD),
          unselectedItemColor: Colors.white54,
          selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(_discSvg, 0),
              label: 'Плейлисты',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(_musicSvg, 1),
              label: 'Музыка',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(_calendarSvg, 2),
              label: 'Календарь',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(_userSvg, 3),
              label: 'Профиль',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(String svg, int index) {
    final isSelected = _selectedIndex == index;
    return SvgPicture.string(
      svg,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(
        isSelected ? const Color(0xFF66DEDD) : Colors.white54,
        BlendMode.srcIn,
      ),
    );
  }
}

class _MiniPlayerBar extends StatefulWidget {
  const _MiniPlayerBar({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_MiniPlayerBar> createState() => _MiniPlayerBarState();
}

class _MiniPlayerBarState extends State<_MiniPlayerBar> {
  bool _uiIsPlaying = false;

  @override
  void initState() {
    super.initState();
    _uiIsPlaying = PlayerController.instance.isPlaying;
    PlayerController.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    PlayerController.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {
        _uiIsPlaying = PlayerController.instance.isPlaying;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = PlayerController.instance;
    final currentTrack = player.currentTrack;
    final hasTrack = currentTrack != null;

    if (!hasTrack) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1727),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF66DEDD).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.music_note, color: Color(0xFF66DEDD), size: 22),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MarqueeText(
                  text: currentTrack['title'] as String? ?? 'Без названия',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                _MarqueeText(
                  text: currentTrack['artist'] as String? ?? 'Неизвестно',
                  style: const TextStyle(color: Colors.white54, fontSize: 9.2),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatDuration(player.position),
                      style: const TextStyle(color: Colors.white54, fontSize: 8.5),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFFFFD54F),
                          inactiveTrackColor: Colors.white12,
                          thumbColor: const Color(0xFFFFD54F),
                          overlayColor: const Color(0xFFFFD54F).withValues(alpha: 0.25),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                          trackHeight: 1.7,
                        ),
                        child: Slider(
                          value: player.duration.inMilliseconds > 0
                              ? player.position.inMilliseconds.clamp(0, player.duration.inMilliseconds).toDouble()
                              : 0,
                          max: player.duration.inMilliseconds > 0 ? player.duration.inMilliseconds.toDouble() : 1,
                          onChanged: (value) async {
                            await player.seekTo(Duration(milliseconds: value.toInt()));
                          },
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(player.duration),
                      style: const TextStyle(color: Colors.white54, fontSize: 8.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: () async {
                  await player.playPrevious();
                  _refresh();
                  widget.onTap();
                },
                icon: const Icon(Icons.skip_previous, color: Colors.white, size: 16),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF66DEDD),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  onPressed: () async {
                    setState(() {
                      _uiIsPlaying = !_uiIsPlaying;
                    });
                    await player.togglePlayback();
                    _refresh();
                    widget.onTap();
                  },
                  icon: Icon(
                    _uiIsPlaying || player.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: () async {
                  await player.playNext();
                  _refresh();
                  widget.onTap();
                },
                icon: const Icon(Icons.skip_next, color: Colors.white, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _MarqueeText extends StatefulWidget {
  const _MarqueeText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.linear);
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final shouldMarquee = textPainter.width > constraints.maxWidth;

        if (!shouldMarquee) {
          return Text(widget.text, style: widget.style, overflow: TextOverflow.ellipsis, maxLines: 1);
        }

        return SizedBox(
          height: 16,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return ClipRect(
                child: Transform.translate(
                  offset: Offset(-_animation.value * 24, 0),
                  child: Text(widget.text, style: widget.style, overflow: TextOverflow.visible, maxLines: 1),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class PlaylistsTab extends StatefulWidget {
  const PlaylistsTab({super.key});

  @override
  State<PlaylistsTab> createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends State<PlaylistsTab> {
  late Future<List<Map<String, Object?>>> _playlistsFuture;

  @override
  void initState() {
    super.initState();
    _playlistsFuture = AppDatabase.instance.getPlaylists();
  }

  void _refreshPlaylists() {
    setState(() {
      _playlistsFuture = AppDatabase.instance.getPlaylists();
    });
  }

  Future<void> _showCreatePlaylistDialog() async {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF101820),
          title: const Text('Создать плейлист', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Название',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subtitleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Подзаголовок',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final subtitle = subtitleController.text.trim();

                if (title.isEmpty) return;

                await AppDatabase.instance.insertPlaylist({
                  'title': title,
                  'subtitle': subtitle.isEmpty ? 'Новый плейлист' : subtitle,
                  'accent': _randomPlaylistAccent(),
                  'createdAt': DateTime.now().toIso8601String(),
                });

                if (!mounted) return;
                Navigator.pop(context);
                _refreshPlaylists();
              },
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Плейлисты',
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Твои подборки и любимые миксы',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _showCreatePlaylistDialog,
                icon: const Icon(Icons.add, color: Color(0xFF66DEDD), size: 28),
                tooltip: 'Создать плейлист',
              ),
            ],
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
                return GridView.builder(
                  itemCount: playlists.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.86,
                  ),
                  itemBuilder: (context, index) {
                    final item = playlists[index];
                    final accent = _parseColor(item['accent'] as String? ?? '#5C7CFA');
                    final playlistId = item['id'] as int;

                    return Dismissible(
                      key: ValueKey(playlistId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        await AppDatabase.instance.deletePlaylist(playlistId);
                        _refreshPlaylists();
                      },
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaylistDetailsScreen(
                                playlistId: playlistId,
                                onPlayQueue: (queue, {required startIndex}) {
                                  PlayerController.instance.playQueue(
                                    queue: queue,
                                    startIndex: startIndex,
                                    sourceType: 'playlist',
                                    sourceId: playlistId,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1624),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Center(
                                    child: SvgPicture.string(
                                      _discSvg,
                                      width: 44,
                                      height: 44,
                                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item['title'] as String? ?? 'Плейлист',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(item['subtitle'] as String? ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
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
    );
  }
}

class PlaylistDetailsScreen extends StatefulWidget {
  final int playlistId;
  final void Function(List<Map<String, Object?>> queue, {required int startIndex}) onPlayQueue;

  const PlaylistDetailsScreen({super.key, required this.playlistId, required this.onPlayQueue});

  @override
  State<PlaylistDetailsScreen> createState() => _PlaylistDetailsScreenState();
}

class _PlaylistDetailsScreenState extends State<PlaylistDetailsScreen> {
  late Future<Map<String, Object?>> _playlistFuture;
  late Future<List<Map<String, Object?>>> _tracksFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _playlistFuture = AppDatabase.instance.getPlaylists().then((playlists) {
        return playlists.firstWhere(
          (item) => item['id'] == widget.playlistId,
          orElse: () => {
            'id': widget.playlistId,
            'title': 'Плейлист',
            'subtitle': '',
            'accent': '#66DEDD',
          },
        );
      });
      _tracksFuture = AppDatabase.instance.getPlaylistTracks(widget.playlistId);
    });
  }

  Future<void> _deleteTrack(int trackId) async {
    await AppDatabase.instance.deleteTrack(trackId);
    _refresh();
  }

  Future<List<Map<String, Object?>>> _loadAvailableTracks() async {
    final allTracks = await AppDatabase.instance.getAllTracks();
    final currentTracks = await AppDatabase.instance.getPlaylistTracks(widget.playlistId);
    final currentKeys = currentTracks
        .map((track) => '${track['title'] ?? ''}::${track['artist'] ?? ''}')
        .toSet();

    return allTracks.where((track) {
      final key = '${track['title'] ?? ''}::${track['artist'] ?? ''}';
      return !currentKeys.contains(key);
    }).toList();
  }

  Future<void> _showAddTrackSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF0B1624),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Добавить из библиотеки',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: FutureBuilder<List<Map<String, Object?>>>(
                  future: _loadAvailableTracks(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF66DEDD)));
                    }

                    final tracks = snapshot.data ?? [];
                    if (tracks.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('Все треки уже добавлены в этот плейлист', style: TextStyle(color: Colors.white54)),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: tracks.length,
                      separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            track['title'] as String? ?? 'Без названия',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            track['artist'] as String? ?? 'Неизвестно',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          trailing: IconButton(
                            onPressed: () async {
                              await AppDatabase.instance.insertTrack({
                                'playlistId': widget.playlistId,
                                'title': track['title'] as String? ?? 'Без названия',
                                'artist': track['artist'] as String? ?? 'Неизвестно',
                                'cover': track['cover'] as String? ?? '#1B3A6A',
                                'filePath': track['filePath'] as String? ?? '',
                              });
                              if (!mounted) return;
                              Navigator.pop(sheetContext);
                              _refresh();
                            },
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF66DEDD)),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020912),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020912),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Плейлист'),
        actions: [
          IconButton(
            onPressed: _showAddTrackSheet,
            icon: const Icon(Icons.add, color: Color(0xFF66DEDD), size: 28),
            tooltip: 'Добавить трек',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, Object?>>(
        future: _playlistFuture,
        builder: (context, playlistSnapshot) {
          if (!playlistSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF66DEDD)));
          }

          final playlist = playlistSnapshot.data!;
          final accent = _parseColor(playlist['accent'] as String? ?? '#66DEDD');

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1624),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Icon(Icons.queue_music_rounded, color: Colors.white, size: 28),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  playlist['title'] as String? ?? 'Плейлист',
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  playlist['subtitle'] as String? ?? '',
                                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Треки', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: FutureBuilder<List<Map<String, Object?>>>(
                        future: _tracksFuture,
                        builder: (context, tracksSnapshot) {
                          if (!tracksSnapshot.hasData) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFF66DEDD)));
                          }

                          final tracks = tracksSnapshot.data ?? [];
                          if (tracks.isEmpty) {
                            return const Center(
                              child: Text('В этом плейлисте пока нет треков', style: TextStyle(color: Colors.white54)),
                            );
                          }

                          return ListView.separated(
                            itemCount: tracks.length,
                            separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                            itemBuilder: (context, index) {
                              final track = tracks[index];
                              return Dismissible(
                                key: ValueKey(track['id']),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: Colors.red,
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (_) async {
                                  await _deleteTrack(track['id'] as int);
                                },
                                child: GestureDetector(
                                  onTap: () => widget.onPlayQueue(
                                    tracks.map((item) => {
                                      'id': item['id'],
                                      'playlistId': widget.playlistId,
                                      'title': item['title'],
                                      'artist': item['artist'],
                                      'cover': item['cover'],
                                      'filePath': item['filePath'],
                                    }).toList(),
                                    startIndex: index,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 6,
                                          child: Text(
                                            track['title'] as String? ?? 'Без названия',
                                            style: const TextStyle(color: Colors.white, fontSize: 15),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: Text(
                                            track['artist'] as String? ?? 'Неизвестно',
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(color: Colors.white54, fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
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
              Positioned(
                left: 6,
                right: 6,
                bottom: 4,
                child: _MiniPlayerBar(onTap: () => setState(() {})),
              ),
            ],
          );
        },
      ),
    );
  }
}

Color _parseColor(String value) {
  final normalized = value.replaceFirst('#', '');
  if (normalized.length == 6) {
    return Color(int.parse('0xFF$normalized'));
  }
  return const Color(0xFF5C7CFA);
}
