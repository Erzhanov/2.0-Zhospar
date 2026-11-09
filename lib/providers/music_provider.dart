import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class MusicTrack {
  final String id;
  final String label;
  final String artist;
  final String icon;
  final String? url;

  const MusicTrack({
    required this.id,
    required this.label,
    required this.artist,
    required this.icon,
    this.url,
  });
}

class MusicProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  MusicTrack? _currentTrack;
  bool _isMinimized = false;
  bool _showPlayer = false;

  bool get isPlaying => _isPlaying;
  MusicTrack? get currentTrack => _currentTrack;
  bool get isMinimized => _isMinimized;
  bool get showPlayer => _showPlayer;

  static const List<MusicTrack> presetTracks = [
    MusicTrack(
      id: '1',
      label: 'Lofi Study Beats',
      artist: 'Lofi Girl',
      icon: '🎧',
    ),
    MusicTrack(
      id: '2',
      label: 'Jazz Hop Relax',
      artist: 'Chillhop',
      icon: '☕',
    ),
    MusicTrack(
      id: '3',
      label: 'Deep Focus & Rain',
      artist: 'Lofi Mix',
      icon: '🌧️',
    ),
    MusicTrack(
      id: '4',
      label: 'Calm Piano Melodies',
      artist: 'Piano Cover',
      icon: '🎹',
    ),
    MusicTrack(
      id: '5',
      label: 'Night Walk Ambient',
      artist: 'Ambient',
      icon: '🌙',
    ),
    MusicTrack(
      id: '6',
      label: 'Қазақ Lo-Fi',
      artist: 'Qazaq Chill',
      icon: '🇰🇿',
    ),
  ];

  MusicProvider() {
    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });
  }

  void playTrack(MusicTrack track) {
    _currentTrack = track;
    _isPlaying = true;
    _showPlayer = true;
    _isMinimized = false;
    notifyListeners();
  }

  void togglePlay() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void stop() {
    _isPlaying = false;
    _currentTrack = null;
    _showPlayer = false;
    _isMinimized = false;
    notifyListeners();
  }

  void setMinimized(bool val) {
    _isMinimized = val;
    notifyListeners();
  }

  Future<void> playChime() async {
    // Generates or plays a chime notification sound
    try {
      // In Flutter we can use audioplayers with source or haptic feedback
    } catch (_) {}
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
