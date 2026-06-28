import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../Api/apiService.dart';

class MainChat extends StatefulWidget {
  final int partnerId;
  final String partnerName;
  final bool isDarkMode;

  const MainChat({
    super.key,
    required this.partnerId,
    required this.partnerName,
    required this.isDarkMode,
  });

  @override
  State<MainChat> createState() => _MainChatState();
}

class _MainChatState extends State<MainChat> {
  final _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  WebSocketChannel? _socket;
  Timer? _reconnectTimer;
  bool _loading = true;
  String? _error;
  String? _runningAction;

  @override
  void initState() {
    super.initState();
    _load();
    _connect();
  }

  Future<void> _load() async {
    try {
      final messages = await ApiService.instance.messages();
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(messages.cast<Map<String, dynamic>>());
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  void _connect() {
    try {
      _socket = ApiService.instance.chatSocket();
      _socket!.stream.listen(
        (raw) {
          final event = jsonDecode(raw as String) as Map<String, dynamic>;
          _upsert(event['message'] as Map<String, dynamic>);
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!mounted || _reconnectTimer != null) return;
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      _reconnectTimer = null;
      _connect();
    });
  }

  void _upsert(Map<String, dynamic> message) {
    if (!mounted) return;
    setState(() {
      final index = _messages.indexWhere(
        (existing) => existing['id'] == message['id'],
      );
      if (index >= 0) {
        _messages[index] = message;
      } else {
        _messages.add(message);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    try {
      _upsert(await ApiService.instance.sendMessage(text));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _suggestDate() async {
    var budgetInput = '2000';
    final budget = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode
            ? const Color(0xFF2D2D2D)
            : Colors.white,
        title: Text(
          'Бюджет свидания',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.brown,
          ),
        ),
        content: TextFormField(
          initialValue: budgetInput,
          onChanged: (value) => budgetInput = value,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.brown,
          ),
          decoration: const InputDecoration(
            prefixText: '₽ ',
            hintText: '2000',
            labelText: 'До какой суммы?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(
                budgetInput.trim().replaceAll(',', '.'),
              );
              if (parsed != null && parsed >= 0) {
                Navigator.pop(context, parsed);
              }
            },
            child: const Text('Предложить'),
          ),
        ],
      ),
    );
    if (budget == null || !mounted) return;
    await _runAssistantAction(
      'date',
      () => ApiService.instance.suggestDate(budget),
    );
  }

  Future<void> _runAssistantAction(
    String action,
    Future<Map<String, dynamic>> Function() request,
  ) async {
    if (_runningAction != null) return;
    setState(() {
      _runningAction = action;
      _error = null;
    });
    try {
      final result = await request();
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _AssistantResultSheet(
          action: action,
          result: result,
          isDarkMode: widget.isDarkMode,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'ИИ-сервис сейчас недоступен. Попробуйте позже.';
        });
      }
    } finally {
      if (mounted) setState(() => _runningAction = null);
    }
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _socket?.sink.close();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.brown;
    final secondary = isDark ? const Color(0xFFB0B0B0) : Colors.brown.shade600;
    final cardColor = isDark ? const Color(0xFF2D2D2D) : Colors.white;
    final inputBg = isDark ? const Color(0xFF2D2D2D) : Colors.white;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'ИИ Ассистент',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                Text(
                  'Советы для ${widget.partnerName}',
                  style: TextStyle(color: secondary),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _AssistantActionButton(
                  icon: Icons.favorite_outline_rounded,
                  label: 'Идея свидания',
                  loading: _runningAction == 'date',
                  enabled: _runningAction == null,
                  isDarkMode: isDark,
                  onPressed: _suggestDate,
                ),
                const SizedBox(width: 8),
                _AssistantActionButton(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Подобрать подарок',
                  loading: _runningAction == 'gift',
                  enabled: _runningAction == null,
                  isDarkMode: isDark,
                  onPressed: () => _runAssistantAction(
                    'gift',
                    () => ApiService.instance.recommend('gift'),
                  ),
                ),
                const SizedBox(width: 8),
                _AssistantActionButton(
                  icon: Icons.insights_rounded,
                  label: 'Анализ отношений',
                  loading: _runningAction == 'analysis',
                  enabled: _runningAction == null,
                  isDarkMode: isDark,
                  onPressed: () => _runAssistantAction(
                    'analysis',
                    ApiService.instance.analyzeRelationship,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      'Начните диалог',
                      style: TextStyle(color: secondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message['sender'] == 'user';
                      final failed = message['deliveryStatus'] == 'failed';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.brown.shade400 : cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                message['message'] as String,
                                style: TextStyle(
                                  color: isUser ? Colors.white : textColor,
                                ),
                              ),
                              if (isUser)
                                Text(
                                  failed
                                      ? 'Не отправлено'
                                      : message['deliveryStatus'] == 'pending'
                                      ? 'Отправка...'
                                      : '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: failed
                                        ? Colors.red.shade100
                                        : Colors.white70,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => _sendMessage(),
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Напишите вопрос...',
                      hintStyle: TextStyle(color: secondary),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.brown,
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool loading;
  final bool enabled;
  final bool isDarkMode;
  final VoidCallback onPressed;

  const _AssistantActionButton({
    required this.icon,
    required this.label,
    required this.loading,
    required this.enabled,
    required this.isDarkMode,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final background = isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;
    final foreground = isDarkMode ? const Color(0xFFD4A574) : Colors.brown;
    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: loading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foreground,
              ),
            )
          : Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: background,
        side: BorderSide(
          color: isDarkMode ? Colors.brown.shade700 : Colors.brown.shade200,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class _AssistantResultSheet extends StatelessWidget {
  final String action;
  final Map<String, dynamic> result;
  final bool isDarkMode;

  const _AssistantResultSheet({
    required this.action,
    required this.result,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final background = isDarkMode
        ? const Color(0xFF242424)
        : const Color(0xFFFFFBF5);
    final textColor = isDarkMode ? Colors.white : Colors.brown.shade900;
    final secondary = isDarkMode
        ? const Color(0xFFB0B0B0)
        : Colors.brown.shade600;
    final content = action == 'analysis'
        ? _analysisContent(textColor, secondary)
        : _suggestionContent(textColor, secondary);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.brown.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              content,
            ],
          ),
        ),
      ),
    );
  }

  Widget _suggestionContent(Color textColor, Color secondary) {
    final isDate = action == 'date';
    final price = (isDate ? result['estimated_cost'] : result['price']) as num?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isDate ? Icons.favorite_rounded : Icons.card_giftcard_rounded,
              color: Colors.brown,
            ),
            const SizedBox(width: 10),
            Text(
              isDate ? 'Идея свидания' : 'Рекомендация подарка',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          result['title'] as String? ?? '',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          result['description'] as String? ?? '',
          style: TextStyle(fontSize: 15, height: 1.4, color: secondary),
        ),
        const SizedBox(height: 16),
        if (price != null)
          _detail(
            isDate ? 'Ориентировочная стоимость' : 'Цена',
            '${price.toStringAsFixed(0)} ₽',
            textColor,
            secondary,
          ),
        if (!isDate && (result['reason'] as String?)?.isNotEmpty == true)
          _detail(
            'Почему это подходит',
            result['reason'] as String,
            textColor,
            secondary,
          ),
      ],
    );
  }

  Widget _analysisContent(Color textColor, Color secondary) {
    final strengths = (result['strengths'] as List<dynamic>? ?? [])
        .cast<String>();
    final growth = (result['growth_areas'] as List<dynamic>? ?? [])
        .cast<String>();
    final actions = (result['suggested_actions'] as List<dynamic>? ?? [])
        .map((item) => (item as Map<String, dynamic>)['action'] as String)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.insights_rounded, color: Colors.brown),
            const SizedBox(width: 10),
            Text(
              'Анализ отношений',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _listSection('Сильные стороны', strengths, textColor, secondary),
        _listSection('Точки роста', growth, textColor, secondary),
        _listSection('Что можно сделать', actions, textColor, secondary),
      ],
    );
  }

  Widget _detail(String label, String value, Color textColor, Color secondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: secondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, color: textColor)),
        ],
      ),
    );
  }

  Widget _listSection(
    String title,
    List<String> items,
    Color textColor,
    Color secondary,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 5),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('• $item', style: TextStyle(color: secondary)),
            ),
          ),
        ],
      ),
    );
  }
}
