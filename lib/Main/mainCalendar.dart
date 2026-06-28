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
  List<Map<String, Object?>> _stationsData = [];
  List<Map<String, Object?>> _radioSlots = [];
  int? _selectedStationId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDate = now;
    _loadPlaylists();
    _loadStations();
  }

  @override
  Widget build(BuildContext context) {
    final days = _buildDaysForMonth(_currentMonth);
    final monthLabel = _monthLabel(_currentMonth);
    final compactDays = _buildCompactDays(_selectedDate);
    final calendarMaxHeight = MediaQuery.of(context).size.height * 0.42;
    final selectedStationTitle = _stationTitleById(_selectedStationId) ?? 'Станция не выбрана';
    final slotsCountLabel = _radioSlots.length == 1
        ? '1 слот'
        : _radioSlots.length < 5
            ? '${_radioSlots.length} слота'
            : '${_radioSlots.length} слотов';

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Радиостанции',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Сначала создай станцию, потом наполняй её плейлистами по календарю',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _showCreateStationDialog,
                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFF66DEDD)),
                    tooltip: 'Создать радиостанцию',
                  ),
                  IconButton(
                    onPressed: _selectedStationId == null ? null : _showAddSlotDialog,
                    icon: const Icon(Icons.radio, color: Color(0xFF66DEDD)),
                    tooltip: 'Добавить слот эфира',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_stationsData.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1624),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: const Text(
                'Пока нет станций. Создай первую и начни строить эфир.',
                style: TextStyle(color: Colors.white54),
              ),
            )
          else
            SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _stationsData.length,
                itemBuilder: (context, index) {
                  final station = _stationsData[index];
                  final stationId = station['id'] as int;
                  final title = station['title'] as String;
                  final isSelected = stationId == _selectedStationId;
                  return GestureDetector(
                    onTap: () => _selectStation(stationId),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF66DEDD) : const Color(0xFF0F1723),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? const Color(0xFF66DEDD) : const Color(0xFF1F2A3B)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isSelected ? 'Выбрано' : 'Открыть',
                            style: TextStyle(
                              color: isSelected ? Colors.black54 : Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF66DEDD).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.radio, color: Color(0xFF66DEDD)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedStationTitle,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'На ${_formatDayLabel(_selectedDate)} — $slotsCountLabel',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
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
                          height: 72,
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
                  'Эфир выбранной станции',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Слоты по расписанию',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (_selectedStationId == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Сначала создай радиостанцию, а потом добавляй в неё плейлисты.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                else if (_radioSlots.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Пока здесь нет плейлистов. Добавь первый слот и запусти эфир.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                else ..._buildSlotRows(),
              ],
            ),
          ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onDateSelected(DateTime day) async {
    if (day.year == _selectedDate.year && day.month == _selectedDate.month && day.day == _selectedDate.day) {
      return;
    }

    setState(() => _selectedDate = day);
    await _loadSlotsForDate(day);
  }

  Future<void> _loadPlaylists() async {
    final playlists = await AppDatabase.instance.getPlaylists();
    if (!mounted) return;
    setState(() => _playlistsData = playlists);
  }

  Future<void> _loadStations() async {
    final stations = await AppDatabase.instance.getRadioStations();
    if (!mounted) return;
    setState(() {
      _stationsData = stations;
      if (_stationsData.isNotEmpty && (_selectedStationId == null || !_stationsData.any((station) => station['id'] == _selectedStationId))) {
        _selectedStationId = _stationsData.first['id'] as int;
      }
    });
    if (_selectedStationId != null) {
      await _loadSlotsForDate(_selectedDate, stationId: _selectedStationId!);
    }
  }

  Future<void> _selectStation(int stationId) async {
    setState(() => _selectedStationId = stationId);
    await _loadSlotsForDate(_selectedDate, stationId: stationId);
  }

  Future<void> _loadSlotsForDate(DateTime day, {int? stationId}) async {
    final dateKey = _formatDate(day);
    final currentStationId = stationId ?? _selectedStationId;
    if (currentStationId == null) {
      if (!mounted) return;
      setState(() => _radioSlots = []);
      return;
    }

    final slots = await AppDatabase.instance.getRadioSlotsByDateAndStation(dateKey, currentStationId);
    if (!mounted) return;
    _radioSlots = slots;
    _radioSlots.sort((a, b) {
      final first = (a['slotTime'] as String?) ?? '00:00';
      final second = (b['slotTime'] as String?) ?? '00:00';
      return first.compareTo(second);
    });
    setState(() {});
  }

  Future<void> _saveSlot(String time, int playlistId) async {
    if (_selectedStationId == null) return;
    final dateKey = _formatDate(_selectedDate);
    await AppDatabase.instance.saveRadioSlot(
      dayDate: dateKey,
      slotTime: time,
      stationId: _selectedStationId!,
      playlistId: playlistId,
      note: _playlistTitleById(playlistId),
    );
    await _loadSlotsForDate(_selectedDate, stationId: _selectedStationId!);
  }

  Future<void> _showCreateStationDialog() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A121F),
          title: const Text('Новая радиостанция', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Например: Утренний эфир',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF66DEDD))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Создать', style: TextStyle(color: Color(0xFF66DEDD))),
            ),
          ],
        );
      },
    );

    if (title == null || title.isEmpty || !mounted) return;

    await AppDatabase.instance.insertRadioStation({
      'title': title,
      'accent': '#66DEDD',
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _loadStations();
  }

  Future<int?> _showPlaylistChoice({int? currentPlaylistId}) async {
    if (_playlistsData.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сначала создайте плейлист в разделе Плейлисты.')),
        );
      }
      return null;
    }

    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF0A121F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
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
                  final isSelected = currentPlaylistId == id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    selected: isSelected,
                    selectedTileColor: const Color(0xFF66DEDD).withValues(alpha: 0.16),
                    title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: subtitle == null ? null : Text(subtitle, style: const TextStyle(color: Colors.white54)),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF66DEDD)) : null,
                    onTap: () => Navigator.of(context).pop(id),
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddSlotDialog() async {
    if (_selectedStationId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сначала создайте радиостанцию.')),
        );
      }
      return;
    }

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
    if (picked == null || !mounted) return;

    final time = picked.format(context);
    final playlistId = await _showPlaylistChoice();
    if (!mounted || playlistId == null) return;

    await _saveSlot(time, playlistId);
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDayLabel(DateTime date) {
    final weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  String? _stationTitleById(int? id) {
    if (id == null) return null;
    for (final item in _stationsData) {
      if (item['id'] == id) {
        return item['title'] as String?;
      }
    }
    return null;
  }

  String? _playlistTitleById(int? id) {
    if (id == null) return null;
    for (final item in _playlistsData) {
      if (item['id'] == id) {
        return item['title'] as String?;
      }
    }
    return null;
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

  List<Widget> _buildSlotRows() {
    return _radioSlots.map((slot) {
      final slotTime = slot['slotTime'] as String? ?? '00:00';
      final playlistId = slot['playlistId'] as int?;
      final playlistTitle = _playlistTitleById(playlistId);

      return Dismissible(
        key: ValueKey(slot['id']),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: Colors.red,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) async {
          await AppDatabase.instance.deleteRadioSlot(slot['id'] as int);
          await _loadSlotsForDate(_selectedDate, stationId: _selectedStationId);
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      slotTime,
                      style: const TextStyle(color: Color(0xFF66DEDD), fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      playlistTitle ?? 'Плейлист не выбран',
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white54, size: 20),
                    onPressed: () async {
                      final newPlaylistId = await _showPlaylistChoice(currentPlaylistId: playlistId);
                      if (newPlaylistId != null) {
                        await AppDatabase.instance.saveRadioSlot(
                          dayDate: _formatDate(_selectedDate),
                          slotTime: slotTime,
                          stationId: _selectedStationId!,
                          playlistId: newPlaylistId,
                          note: _playlistTitleById(newPlaylistId),
                        );
                        await _loadSlotsForDate(_selectedDate, stationId: _selectedStationId);
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
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
