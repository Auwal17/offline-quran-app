import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart'; //
// Import the Surah model we created earlier
import '../../models/surah_model.dart';

class QuranAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  Timer? _sleepTimer;

  QuranAudioHandler() {
    // This is crucial: It constantly updates the OS with the current state
    // (playing, paused, loading) so the lock screen controls stay in sync.
    _player.playbackEventStream.listen(_broadcastState);
  }

  /// Custom method to load a Surah from local assets and update the lock screen UI
  Future<void> loadSurah(Surah surah,
      {String sheikhName = "Mishary Alafasy"}) async {
    // 1. Tell the OS what is about to play (Updates the lock screen notification)
    mediaItem.add(MediaItem(
      id: surah.id.toString(),
      title: surah.nameEnglish,
      artist: sheikhName,
      duration: surah.audioDuration,
      // artUri: Uri.parse('asset:///assets/images/sheikh_cover.jpg'), // Uncomment when you add your image
    ));

    // 2. Load the actual offline audio file
    // 2. Load the actual offline audio file
    try {
      await _player.setAsset(surah.audioAssetPath);
    } catch (e) {
      debugPrint(
          "Error loading audio asset: $e"); // <-- Changed from print to debugPrint
    }
  }

  // --- STANDARD PLAYBACK CONTROLS ---

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() async {
    await _player.pause();

    // Auto-save the position when playback pauses
    final currentMediaItem = mediaItem.value;
    if (currentMediaItem != null) {
      final surahId = int.tryParse(currentMediaItem.id);
      if (surahId != null) {
        // We instantiate the box directly here to avoid passing Riverpod ref into the isolate
        final historyBox = Hive.box('history_box');
        historyBox.put('last_surah_id', surahId);
        historyBox.put('last_position', _player.position.inSeconds);
      }
    }
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  // --- SLEEP TIMER FEATURE ---

  /// Starts a countdown that pauses playback when it reaches zero
  Future<void> startSleepTimer(Duration duration) async {
    _sleepTimer?.cancel(); // Cancel any existing timer
    _sleepTimer = Timer(duration, () {
      pause();
    });
  }

  /// Cancels the active sleep timer
  void cancelSleepTimer() {
    _sleepTimer?.cancel();
  }

  // --- OS STATE SYNCHRONIZATION ---

  /// Broadcasts the current internal state of just_audio to audio_service
  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;

    // Map just_audio's processing state to audio_service's processing state
    final processingState = const {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[_player.processingState]!;

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [
        0,
        1,
        3
      ], // The buttons shown on the collapsed notification
      processingState: processingState,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }

  // Expose the raw position stream for the UI progress slider
  Stream<Duration> get positionStream => _player.positionStream;
}
