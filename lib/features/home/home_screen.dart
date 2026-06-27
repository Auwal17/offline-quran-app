import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../models/surah_model.dart';
import '../player/audio_player_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the list of Surahs filtered by search queries
    final surahs = ref.watch(surahListProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Fetch the last played history directly from the persistent Hive database
    final storage = ref.read(storageServiceProvider);
    final lastSurahId =
        storage.getLastPlayedSurahId() ?? 1; // Default to Surah 1 if null
    final lastPosition = storage.getLastPlayedPosition() ?? 0;

    // Determine which Surah to display in the Continue Listening widget
    final continueSurah = surahs.firstWhere(
      (s) => s.id == lastSurahId,
      orElse: () => surahs.isNotEmpty
          ? surahs.first
          : const Surah(
              id: 1,
              nameArabic: 'الفاتحة',
              nameEnglish: 'Al-Fatihah',
              transliteration: 'Al-Fatihah',
              revelationType: 'Meccan',
              audioDuration: Duration(seconds: 45),
              audioAssetPath: 'assets/audio/1.mp3',
            ),
    );

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 1. APP BAR HEADER WITH THEME TOGGLE
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assalamu Alaikum',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Welcome back',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        color: AppTheme.goldAccent,
                      ),
                      onPressed: () {
                        ref.read(themeProvider.notifier).toggleTheme();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // 2. DYNAMIC CONTINUE LISTENING CARD
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryGreen, Color(0xFF1E7A53)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.music_note,
                                    color: AppTheme.goldAccent, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'CONTINUE LISTENING',
                                  style: TextStyle(
                                    color: AppTheme.goldAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              continueSurah.transliteration,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Surah No. ${continueSurah.id} • Mishary Alafasy',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          color: AppTheme.goldAccent,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon:
                              const Icon(Icons.play_arrow, color: Colors.white),
                          onPressed: () {
                            // Sync the state and load data into background engine
                            ref.read(currentSurahProvider.notifier).state =
                                continueSurah;
                            ref
                                .read(audioHandlerProvider)
                                .loadSurah(continueSurah);

                            // Fast-forward playback position to where the user left off
                            if (lastPosition > 0) {
                              ref
                                  .read(audioHandlerProvider)
                                  .seek(Duration(seconds: lastPosition));
                            }

                            // Navigate instantly to full control player interface
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AudioPlayerScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. SEAMLESS SEARCH BAR INTERFACE
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    ref.read(surahListProvider.notifier).search(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search Surah (Name, Number)',
                    prefixIcon:
                        const Icon(Icons.search, color: AppTheme.primaryGreen),
                    filled: true,
                    fillColor: isDarkMode
                        ? AppTheme.surfaceDark
                        : Colors.black54.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),

            // DYNAMIC LIST HEADLINE
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Text(
                  'All Surahs (${surahs.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // 4. PERFORMANCE OPTIMIZED RECYCLER SLIVER LIST
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final surah = surahs[index];
                    return Card(
                      key: ValueKey(surah.id),
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDarkMode ? Colors.white10 : Colors.black12,
                        ),
                      ),
                      color: isDarkMode ? AppTheme.surfaceDark : Colors.white,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${surah.id}',
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          surah.transliteration,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${surah.revelationType} • Offline Audio',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        trailing: Text(
                          surah.nameArabic,
                          style: const TextStyle(
                            fontFamily: 'Uthmani',
                            fontSize: 22,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        onTap: () {
                          // Update active state references
                          ref.read(currentSurahProvider.notifier).state = surah;
                          ref.read(audioHandlerProvider).loadSurah(surah);

                          // Push route onto execution tree stack
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AudioPlayerScreen(),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  childCount: surahs.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
