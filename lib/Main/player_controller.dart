import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../Database/app_database.dart';

class PlayerController extends ChangeNotifier {
  PlayerController._();

  static final PlayerController instance = PlayerController._();

  AudioPlayer? _audioPlayer;
  final List<Map<String, Object?>> _queue = [];
  int _currentIndex = 0;
  String _sourceType = 'library';
  int? _sourceId;
  Map<String, Object?>? _currentTrack;
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _audioAvailable = true;
  bool _listenersAttached = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  List<Map<String, Object?>> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  Map<String, Object?>? get currentTrack => _currentTrack;
  String get sourceType => _sourceType;
  int? get sourceId => _sourceId;
  Duration get position => _position;
  Duration get duration => _duration;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final player = _ensureAudioPlayer();
      _attachPlayerListeners(player);
      player.onPlayerComplete.listen((_) async {
        await playNext();
      });
    } catch (_) {
      _audioAvailable = false;
    }

    await restoreState();
    _isInitialized = true;
  }

  Future<void> playQueue({
    required List<Map<String, Object?>> queue,
    required int startIndex,
    required String sourceType,
    int? sourceId,
  }) async {
    if (queue.isEmpty) return;

    try {
      final player = _ensureAudioPlayer();
      await player.stop();
    } catch (_) {
      _audioAvailable = false;
    }

    _queue
      ..clear()
      ..addAll(queue.map((track) => Map<String, Object?>.from(track)));

    _currentIndex = startIndex.clamp(0, _queue.length - 1);
    _sourceType = sourceType;
    _sourceId = sourceId;
    _currentTrack = _queue[_currentIndex];
    _position = Duration.zero;
    _duration = Duration.zero;
    _isPlaying = true;
    notifyListeners();
    await _persistState();
    await _playCurrent();
  }

  Future<void> togglePlayback() async {
    if (_queue.isEmpty || _currentTrack == null) return;

    if (_isPlaying) {
      if (_audioAvailable) {
        try {
          final player = _ensureAudioPlayer();
          await player.pause();
        } catch (_) {
          _audioAvailable = false;
        }
      }
      _isPlaying = false;
      notifyListeners();
      await _persistState();
      return;
    }

    if (!_audioAvailable) {
      _isPlaying = true;
      notifyListeners();
      await _persistState();
      return;
    }

    try {
      final player = _ensureAudioPlayer();
      if (player.state == PlayerState.paused) {
        await player.resume();
      } else {
        await _playCurrent();
      }
      _isPlaying = true;
    } catch (_) {
      _audioAvailable = false;
      _isPlaying = true;
    }

    notifyListeners();
    await _persistState();
  }

  Future<void> playNext() async {
    if (_queue.isEmpty) return;

    final nextIndex = (_currentIndex + 1) % _queue.length;
    _currentIndex = nextIndex;
    _currentTrack = _queue[_currentIndex];
    await _playCurrent();
  }

  Future<void> playPrevious() async {
    if (_queue.isEmpty) return;

    final prevIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    _currentIndex = prevIndex;
    _currentTrack = _queue[_currentIndex];
    await _playCurrent();
  }

  Future<void> restoreState() async {
    final state = await AppDatabase.instance.getPlayerState();
    if (state == null) return;

    final sourceType = state['sourceType'] as String? ?? 'library';
    final sourceId = state['sourceId'] as int?;
    final currentTrackId = state['currentTrackId'] as int?;
    final currentIndex = (state['currentIndex'] as int?) ?? 0;
    final isPlaying = (state['isPlaying'] as int?) == 1;

    List<Map<String, Object?>> queue = [];
    if (sourceType == 'playlist' && sourceId != null) {
      queue = await AppDatabase.instance.getPlaylistTracks(sourceId);
    } else {
      queue = await AppDatabase.instance.getAllTracks();
    }

    if (queue.isEmpty) return;

    final matchedIndex = queue.indexWhere((track) => (track['id'] as int?) == currentTrackId);
    _queue
      ..clear()
      ..addAll(queue.map((track) => Map<String, Object?>.from(track)));

    _currentIndex = matchedIndex >= 0 ? matchedIndex : currentIndex.clamp(0, _queue.length - 1);
    _sourceType = sourceType;
    _sourceId = sourceId;
    _currentTrack = _queue[_currentIndex];
    _isPlaying = isPlaying;
    notifyListeners();

    if (isPlaying) {
      await _playCurrent();
    }
  }

  Future<void> _playCurrent() async {
    if (_queue.isEmpty || _currentTrack == null) return;

    try {
      final player = _ensureAudioPlayer();
      await player.stop();
    } catch (_) {
      _audioAvailable = false;
    }

    final filePath = _currentTrack!['filePath'] as String?;
    if (filePath == null || filePath.isEmpty) {
      _isPlaying = false;
      notifyListeners();
      await _persistState();
      return;
    }

    if (!_audioAvailable) {
      _isPlaying = false;
      notifyListeners();
      await _persistState();
      return;
    }

    try {
      final player = _ensureAudioPlayer();
      await player.play(DeviceFileSource(filePath));
      _isPlaying = true;
    } catch (_) {
      _audioAvailable = false;
      _isPlaying = false;
    }

    notifyListeners();
    await _persistState();
  }

  Future<void> _persistState() async {
    if (_currentTrack == null) {
      await AppDatabase.instance.clearPlayerState();
      return;
    }

    await AppDatabase.instance.savePlayerState(
      sourceType: _sourceType,
      sourceId: _sourceId,
      currentTrackId: _currentTrack!['id'] as int?,
      currentIndex: _currentIndex,
      isPlaying: _isPlaying,
    );
  }

  AudioPlayer _ensureAudioPlayer() {
    if (_audioPlayer != null) return _audioPlayer!;

    try {
      _audioPlayer = AudioPlayer();
      _audioAvailable = true;
      _attachPlayerListeners(_audioPlayer!);
      return _audioPlayer!;
    } catch (_) {
      _audioAvailable = false;
      throw Exception('Audio player unavailable');
    }
  }

  void _attachPlayerListeners(AudioPlayer player) {
    if (_listenersAttached) return;
    _listenersAttached = true;

    player.onDurationChanged.listen((duration) {
      if (duration != null) {
        _duration = duration;
        notifyListeners();
      }
    });

    player.onPositionChanged.listen((position) {
      _position = position;
      notifyListeners();
    });
  }

  Future<void> seekTo(Duration position) async {
    if (!_audioAvailable) return;

    try {
      final player = _ensureAudioPlayer();
      await player.seek(position);
      _position = position;
      notifyListeners();
    } catch (_) {
      _audioAvailable = false;
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }
}
