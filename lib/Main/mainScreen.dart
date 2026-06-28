import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../Database/app_database.dart';
import 'mainMusic.dart';
import 'mainCalendar.dart';
import 'mainSettings.dart';

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
    _pages = const [
      PlaylistsTab(),
      MusicTab(),
      CalendarTab(),
      SettingsTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020912),
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: _pages),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Плейлисты',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Твои подборки и любимые миксы',
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
                    return Container(
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

Color _parseColor(String value) {
  final normalized = value.replaceFirst('#', '');
  if (normalized.length == 6) {
    return Color(int.parse('0xFF$normalized'));
  }
  return const Color(0xFF5C7CFA);
}
