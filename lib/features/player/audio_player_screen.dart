import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';

class AudioPlayerScreen extends ConsumerWidget {
  const AudioPlayerScreen({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the currently playing Surah
    final currentSurah = ref.watch(currentSurahProvider);

    // Safety check: If nothing is playing, show a blank screen
    if (currentSurah == null) return const Scaffold();

    final playbackStateAsync = ref.watch(playbackStateProvider);
    final positionAsync = ref.watch(positionStreamProvider);
    final audioHandler = ref.read(audioHandlerProvider);
    final allSurahs = ref.watch(surahListProvider);
    final favoriteIds = ref.watch(favoritesProvider);
    final isFavorite = favoriteIds.contains(currentSurah.id);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final maxDurationInSeconds =
        currentSurah.audioDuration.inSeconds.toDouble();

    // 2. Calculate Next/Previous Availability
    final currentIndex = allSurahs.indexWhere((s) => s.id == currentSurah.id);
    final hasPrevious = currentIndex > 0;
    final hasNext = currentIndex < allSurahs.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.timer_outlined),
            tooltip: 'Sleep Timer',
            onSelected: (minutes) {
              if (minutes == 0) {
                audioHandler.cancelSleepTimer();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sleep timer canceled')));
              } else {
                audioHandler.startSleepTimer(Duration(minutes: minutes));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Audio will pause in $minutes minutes')));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 15, child: Text('15 Minutes')),
              const PopupMenuItem(value: 30, child: Text('30 Minutes')),
              const PopupMenuItem(value: 0, child: Text('Cancel Timer')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // ARTWORK
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, Color(0xFF1E7A53)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.menu_book_rounded,
                      size: 100, color: AppTheme.goldAccent),
                ),
              ),
              const SizedBox(height: 40),

              // SURAH INFO (Now updates automatically when Next is pressed)
              Text(
                currentSurah.nameArabic,
                style: const TextStyle(
                    fontFamily: 'Uthmani',
                    fontSize: 36,
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${currentSurah.transliteration} • ${currentSurah.nameEnglish}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // PROGRESS SLIDER
              positionAsync.when(
                data: (position) {
                  final currentPosition = position.inSeconds
                      .toDouble()
                      .clamp(0.0, maxDurationInSeconds);
                  return Column(
                    children: [
                      Slider(
                        value: currentPosition,
                        max: maxDurationInSeconds,
                        onChanged: (value) =>
                            audioHandler.seek(Duration(seconds: value.toInt())),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(position),
                                style: const TextStyle(fontSize: 12)),
                            Text(_formatDuration(currentSurah.audioDuration),
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () =>
                    const LinearProgressIndicator(color: AppTheme.primaryGreen),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // MAIN PLAYBACK CONTROLS (Next, Prev, Play, Skip)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // PREVIOUS SURAH
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? AppTheme.primaryGreen
                          : (isDarkMode ? Colors.white : Colors.black87),
                    ),
                    onPressed: () {
                      // Toggle the database
                      ref
                          .read(favoritesProvider.notifier)
                          .toggle(currentSurah.id);

                      // Show user feedback
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isFavorite
                              ? 'Removed from Favorites'
                              : 'Added to Favorites'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),

                  // SKIP BACKWARD 10s
                  IconButton(
                    iconSize: 28,
                    icon: const Icon(Icons.replay_10),
                    onPressed: () {
                      final currentPos = positionAsync.value ?? Duration.zero;
                      final newPos = currentPos - const Duration(seconds: 10);
                      audioHandler.seek(
                          newPos < Duration.zero ? Duration.zero : newPos);
                    },
                  ),

                  // PLAY/PAUSE
                  playbackStateAsync.when(
                    data: (state) {
                      final isPlaying = state.playing;
                      return Container(
                        decoration: const BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle),
                        child: IconButton(
                          iconSize: 54,
                          color: Colors.white,
                          icon: Icon(isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded),
                          onPressed: isPlaying
                              ? audioHandler.pause
                              : audioHandler.play,
                        ),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Icon(Icons.error),
                  ),

                  // SKIP FORWARD 10s
                  IconButton(
                    iconSize: 28,
                    icon: const Icon(Icons.forward_10),
                    onPressed: () {
                      final currentPos = positionAsync.value ?? Duration.zero;
                      final newPos = currentPos + const Duration(seconds: 10);
                      audioHandler.seek(newPos > currentSurah.audioDuration
                          ? currentSurah.audioDuration
                          : newPos);
                    },
                  ),

                  // NEXT SURAH
                  IconButton(
                    iconSize: 32,
                    color: hasNext
                        ? (isDarkMode ? Colors.white : Colors.black87)
                        : Colors.grey,
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: hasNext
                        ? () {
                            final nextSurah = allSurahs[currentIndex + 1];
                            ref.read(currentSurahProvider.notifier).state =
                                nextSurah;
                            audioHandler.loadSurah(nextSurah);
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // SECONDARY CONTROLS (Speed & Favorite)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PopupMenuButton<double>(
                    icon: const Icon(Icons.speed),
                    tooltip: 'Playback Speed',
                    onSelected: (speed) => audioHandler.setSpeed(speed),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                      const PopupMenuItem(
                          value: 1.0, child: Text('1.0x (Normal)')),
                      const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                      const PopupMenuItem(value: 2.0, child: Text('2.0x')),
                    ],
                  ),
                  const SizedBox(width: 40),
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to Favorites')));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
