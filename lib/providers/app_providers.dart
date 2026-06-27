import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/services/audio_handler.dart';
import '../core/services/storage_service.dart';
import '../models/surah_model.dart';

// ==========================================
// 1. AUDIO ENGINE PROVIDERS
// ==========================================

/// Exposes the background audio handler isolate globally to the application.
/// Overridden inside main.dart during safe async initialization boots.
final audioHandlerProvider = Provider<QuranAudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider not initialized in main.dart');
});

/// Exposes the real-time playback state stream (playing, paused, buffering).
final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.playbackState;
});

/// Exposes the current temporal position stream of the playing file.
final positionStreamProvider = StreamProvider<Duration>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.positionStream;
});

/// Holds the reference state for the Surah object that is currently selected.
final currentSurahProvider = StateProvider<Surah?>((ref) => null);

// ==========================================
// 2. DATA PERSISTENCE LAYER (HIVE)
// ==========================================

/// Exposes the centralized local storage utility service wrapper.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Manages database synchronization for the user's favorite list array.
class FavoritesNotifier extends StateNotifier<List<int>> {
  final StorageService _storage;

  FavoritesNotifier(this._storage) : super(_storage.getFavoriteIds());

  void toggle(int surahId) {
    _storage.toggleFavorite(surahId);
    state =
        _storage.getFavoriteIds(); // Re-fetch array values to notify listeners
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<int>>((ref) {
  final storage = ref.read(storageServiceProvider);
  return FavoritesNotifier(storage);
});

// ==========================================
// 3. THEME MANAGEMENT PROVIDER
// ==========================================

/// Manages dark and light brightness modes, persisting adjustments directly to disk.
class ThemeNotifier extends StateNotifier<ThemeMode> {
  final Box settingsBox = Hive.box('settings_box');

  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    final isDarkMode = settingsBox.get('is_dark_mode');
    if (isDarkMode != null) {
      state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    }
  }

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    settingsBox.put('is_dark_mode', state == ThemeMode.dark);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

// ==========================================
// 4. METADATA ASSET REPOSITORY ENGINE
// ==========================================

/// Handles asynchronous streaming execution loops to read the 114 Surah JSON document.
class SurahNotifier extends StateNotifier<List<Surah>> {
  List<Surah> _allSurahs = []; // Internal master reference list cache

  SurahNotifier() : super([]) {
    _loadSurahsFromAsset();
  }

  Future<void> _loadSurahsFromAsset() async {
    try {
      // Stream the structural data content from the app package binary space
      final String jsonString =
          await rootBundle.loadString('assets/surah_data.json');

      // Transform raw string into deserialized primitive array lists
      final List<dynamic> jsonResponse = json.decode(jsonString);

      // Cast configurations explicitly via factory models
      _allSurahs = jsonResponse.map((data) => Surah.fromJson(data)).toList();

      state = _allSurahs;
    } catch (e) {
      debugPrint(
          "Critical failure loading physical database tracking document: $e");
      state = [];
    }
  }

  void search(String query) {
    if (query.isEmpty) {
      state = _allSurahs;
    } else {
      state = _allSurahs.where((surah) => surah.matchesSearch(query)).toList();
    }
  }
}

final surahListProvider =
    StateNotifierProvider<SurahNotifier, List<Surah>>((ref) {
  return SurahNotifier();
});
