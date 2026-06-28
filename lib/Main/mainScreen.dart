import 'package:flutter/material.dart';
import 'mainChat.dart';
import 'mainInfo.dart';
import 'mainCalendar.dart';
import 'mainSettings.dart';
import '../Api/apiService.dart';

/// Основной экран приложения - навигация
class MainScreen extends StatefulWidget {
  final int partnerId;
  final String partnerName;

  const MainScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;

  late final List<Widget> _screens = [
    MainChat(
      partnerId: widget.partnerId,
      partnerName: widget.partnerName,
      isDarkMode: _isDarkMode,
    ),
    MainInfo(
      partnerId: widget.partnerId,
      partnerName: widget.partnerName,
      isDarkMode: _isDarkMode,
    ),
    MainCalendar(
      partnerId: widget.partnerId,
      partnerName: widget.partnerName,
      isDarkMode: _isDarkMode,
    ),
    MainSettings(
      partnerId: widget.partnerId,
      isDarkMode: _isDarkMode,
      onThemeChanged: _toggleTheme,
      onLogout: _logout,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      // Пересоздаём экраны с новой темой
      _screens[0] = MainChat(
        partnerId: widget.partnerId,
        partnerName: widget.partnerName,
        isDarkMode: _isDarkMode,
      );
      _screens[1] = MainInfo(
        partnerId: widget.partnerId,
        partnerName: widget.partnerName,
        isDarkMode: _isDarkMode,
      );
      _screens[2] = MainCalendar(
        partnerId: widget.partnerId,
        partnerName: widget.partnerName,
        isDarkMode: _isDarkMode,
      );
      _screens[3] = MainSettings(
        partnerId: widget.partnerId,
        isDarkMode: _isDarkMode,
        onThemeChanged: _toggleTheme,
        onLogout: _logout,
      );
    });
  }

  void _logout() async {
    try {
      await ApiService.instance.logout();
    } catch (e) {
      print('[MainScreen] Ошибка выхода: $e');
    }
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color background = _isDarkMode
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFFAEDCD);
    final Color bottomNavBg = _isDarkMode
        ? const Color(0xFF2D2D2D)
        : Colors.white;
    final Color selectedColor = _isDarkMode
        ? const Color(0xFFD4A574)
        : Colors.brown;
    final Color unselectedColor = _isDarkMode
        ? const Color(0xFF666666)
        : Colors.brown.shade300;

    return Scaffold(
      backgroundColor: background,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.chat_rounded), label: 'Чат'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Партнёр',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_rounded),
            label: 'Календарь',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Настройки',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        backgroundColor: bottomNavBg,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
