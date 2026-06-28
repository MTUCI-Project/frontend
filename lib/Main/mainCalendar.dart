import 'package:flutter/material.dart';

import '../Api/apiService.dart';

class MainCalendar extends StatelessWidget {
  final int partnerId;
  final String partnerName;
  final bool isDarkMode;

  const MainCalendar({
    super.key,
    required this.partnerId,
    required this.partnerName,
    required this.isDarkMode,
  });

  Future<List<List<dynamic>>> _load() async => Future.wait([
    ApiService.instance.events(),
    ApiService.instance.todos(),
    ApiService.instance.reminders(),
  ]);

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : Colors.brown;
    final secondary = isDarkMode
        ? const Color(0xFFB0B0B0)
        : Colors.brown.shade600;
    final card = isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Календарь',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                Text(
                  'Важные даты $partnerName',
                  style: TextStyle(color: secondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<List<dynamic>>>(
              future: _load(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Не удалось загрузить календарь',
                      style: TextStyle(color: textColor),
                    ),
                  );
                }
                final values = snapshot.data!;
                final events = values[0];
                final todos = values[1];
                final reminders = values[2]
                    .where((r) => (r as Map)['is_active'] == true)
                    .toList();
                if (events.isEmpty && todos.isEmpty && reminders.isEmpty) {
                  return Center(
                    child: Text(
                      'Здесь будут отмечены важные даты',
                      style: TextStyle(color: secondary),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...events.map((raw) {
                      final event = raw as Map<String, dynamic>;
                      return _tile(
                        event['title'] as String,
                        event['date'] as String,
                        Icons.event,
                        card,
                        textColor,
                      );
                    }),
                    ...todos.map((raw) {
                      final todo = raw as Map<String, dynamic>;
                      return _tile(
                        todo['text'] as String,
                        todo['due'] as String? ?? 'Без срока',
                        todo['completed'] == true ? Icons.task_alt : Icons.task,
                        card,
                        textColor,
                      );
                    }),
                    ...reminders.map((raw) {
                      final reminder = raw as Map<String, dynamic>;
                      return _tile(
                        reminder['text'] as String? ?? 'Напоминание',
                        reminder['remind_at'] as String? ?? '',
                        Icons.notifications,
                        card,
                        textColor,
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    String title,
    String subtitle,
    IconData icon,
    Color card,
    Color textColor,
  ) {
    return Card(
      color: card,
      child: ListTile(
        leading: Icon(icon, color: Colors.brown),
        title: Text(title, style: TextStyle(color: textColor)),
        subtitle: Text(subtitle, style: TextStyle(color: textColor)),
      ),
    );
  }
}
