import 'package:flutter/material.dart';
import '../Database/app_database.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;
  bool _isExpanded = false;
  List<Map<String, Object?>> _playlistsData = [];
  final Map<String, int?> _timeAssignments = {};
  final List<String> _selectedDayTimes = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDate = now;
    _loadPlaylists();
    _loadAssignmentsForDay(now);
  }

  @override
  Widget build(BuildContext context) {
    final days = _buildDaysForMonth(_currentMonth);
    final monthLabel = _monthLabel(_currentMonth);
    final compactDays = _buildCompactDays(_selectedDate);
    final calendarMaxHeight = MediaQuery.of(context).size.height * 0.42;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Расписание',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: _showAddTimeDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                tooltip: 'Добавить время',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1624),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: calendarMaxHeight),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1)),
                              icon: const Icon(Icons.chevron_left, color: Colors.white),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  monthLabel,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1)),
                              icon: const Icon(Icons.chevron_right, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 68,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: compactDays.length,
                            itemBuilder: (context, index) {
                              final day = compactDays[index];
                              final isSelected = day.year == _selectedDate.year && day.month == _selectedDate.month && day.day == _selectedDate.day;
                              return GestureDetector(
                                onTap: () => _onDateSelected(day),
                                child: Container(
                                  width: 58,
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF00C3C7) : const Color(0xFF0F1723),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isSelected ? const Color(0xFF00C3C7) : const Color(0xFF1F2A3B)),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _weekdayShort(day.weekday),
                                        style: TextStyle(
                                          color: isSelected ? Colors.black : Colors.white54,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${day.day}',
                                        style: TextStyle(
                                          color: isSelected ? Colors.black : Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (_isExpanded) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
                                .map((day) => Expanded(
                                      child: Center(
                                        child: Text(
                                          day,
                                          style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: days.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                            itemBuilder: (context, index) {
                              final day = days[index];
                              final isCurrentMonth = day.month == _currentMonth.month;
                              final isSelected = day.year == _selectedDate.year && day.month == _selectedDate.month && day.day == _selectedDate.day;

                              return GestureDetector(
                                onTap: () => _onDateSelected(day),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF66DEDD) : const Color(0xFF101A2B),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isSelected ? const Color(0xFF66DEDD) : Colors.white12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${day.day}',
                                      style: TextStyle(
                                        color: isCurrentMonth ? Colors.white : Colors.white38,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.white12)),
                    ),
                    child: Center(
                      child: Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: const Color(0xFF66DEDD),
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1624),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Расписание на дату',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                      const SizedBox(height: 8),
                const Text(
                  'Назначения на день',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (_selectedDayTimes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Нет назначений на выбранный день.', style: TextStyle(color: Colors.white54)),
                  )
                else ..._buildScheduleRows(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDateSelected(DateTime day) async {
    setState(() => _selectedDate = day);
    await _loadAssignmentsForDay(day);
  }

  Future<void> _loadPlaylists() async {
    final playlists = await AppDatabase.instance.getPlaylists();
    if (!mounted) return;
    setState(() => _playlistsData = playlists);
  }

  Future<void> _loadAssignmentsForDay(DateTime day) async {
    final datePrefix = _formatDate(day);
    final assignments = await AppDatabase.instance.getAssignmentsByDatePrefix('$datePrefix%');
    if (!mounted) return;
    _selectedDayTimes.clear();
    _timeAssignments.clear();
    for (final row in assignments) {
      final fullDate = row['date'] as String;
      final playlistId = row['playlistId'] as int?;
      final time = fullDate.length >= 16 ? fullDate.substring(11, 16) : '00:00';
      if (!_selectedDayTimes.contains(time)) {
        _selectedDayTimes.add(time);
      }
      _timeAssignments[time] = playlistId;
    }
    _selectedDayTimes.sort();
    setState(() {});
  }

  Future<void> _saveAssignmentForTime(String time, int playlistId) async {
    final dateTimeKey = _formatDateTime(_selectedDate, time);
    final title = _playlistTitleById(playlistId);
    await AppDatabase.instance.saveAssignment(
      dateTimeKey,
      playlistId,
      note: title,
    );
    if (!mounted) return;
    if (!_selectedDayTimes.contains(time)) {
      _selectedDayTimes.add(time);
    }
    _selectedDayTimes.sort();
    _timeAssignments[time] = playlistId;
    setState(() {});
  }

  Future<int?> _showPlaylistChoice() async {
    if (_playlistsData.isEmpty) return null;
    return await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF0A121F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Выберите плейлист',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ..._playlistsData.map((playlist) {
                final id = playlist['id'] as int;
                final title = playlist['title'] as String;
                final subtitle = playlist['subtitle'] as String?;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: subtitle == null ? null : Text(subtitle, style: const TextStyle(color: Colors.white54)),
                  onTap: () => Navigator.of(context).pop(id),
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddTimeDialog() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF66DEDD),
            onPrimary: Colors.black,
            surface: Color(0xFF0B1624),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    if (!mounted) return;
    final time = picked.format(context);
    final playlistId = await _showPlaylistChoice();
    if (!mounted) return;
    if (playlistId != null) {
      await _saveAssignmentForTime(time, playlistId);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date, String time) {
    final datePart = _formatDate(date);
    final normalizedTime = time.padLeft(5, '0');
    return '$datePart $normalizedTime';
  }

  String? _playlistTitleById(int? id) {
    if (id == null) return null;
    return _playlistsData.cast<Map<String, Object?>>().firstWhere(
      (item) => item['id'] == id,
      orElse: () => {},
    )['title'] as String?;
  }

  List<DateTime> _buildDaysForMonth(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final days = <DateTime>[];

    final startOffset = firstWeekday == 7 ? 0 : firstWeekday;
    for (var i = startOffset; i > 0; i--) {
      final prevDay = firstDayOfMonth.subtract(Duration(days: i));
      days.add(prevDay);
    }

    for (var day = 1; day <= daysInMonth; day++) {
      days.add(DateTime(month.year, month.month, day));
    }

    final remaining = 42 - days.length;
    for (var i = 1; i <= remaining; i++) {
      days.add(DateTime(month.year, month.month + 1, i));
    }

    return days;
  }

  List<DateTime> _buildCompactDays(DateTime selectedDate) {
    return List.generate(9, (index) => selectedDate.add(Duration(days: index)));
  }

  List<Widget> _buildScheduleRows() {
    return _selectedDayTimes.map((time) {
      final playlistId = _timeAssignments[time];
      final playlistTitle = _playlistTitleById(playlistId);

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF101A2B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F2A3B)),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1B2A3B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  time,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Плейлист',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    playlistTitle ?? 'Плейлист не выбран',
                    style: TextStyle(
                      color: playlistTitle != null ? Colors.white : Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () async {
                final playlistId = await _showPlaylistChoice();
                if (playlistId != null) {
                  await _saveAssignmentForTime(time, playlistId);
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF66DEDD)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                foregroundColor: const Color(0xFF66DEDD),
              ),
              child: const Text('Выбрать'),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _weekdayShort(int weekday) {
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return days[(weekday + 6) % 7];
  }

  String _monthLabel(DateTime month) {
    final monthNames = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return '${monthNames[month.month - 1]} ${month.year}';
  }
}
