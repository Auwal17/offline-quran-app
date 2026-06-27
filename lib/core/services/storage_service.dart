import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  final Box _favoritesBox = Hive.box('favorites_box');
  final Box _historyBox = Hive.box('history_box');

  // ==========================================
  // FAVORITES LOGIC
  // ==========================================

  bool isFavorite(int surahId) {
    return _favoritesBox.containsKey(surahId);
  }

  void toggleFavorite(int surahId) {
    if (isFavorite(surahId)) {
      _favoritesBox.delete(surahId);
    } else {
      _favoritesBox.put(surahId, true); // We just store 'true' against the ID
    }
  }

  List<int> getFavoriteIds() {
    // Returns a list of all saved Surah IDs
    return _favoritesBox.keys.cast<int>().toList();
  }

  // ==========================================
  // CONTINUE LISTENING LOGIC
  // ==========================================

  void saveLastPlayed(int surahId, int positionInSeconds) {
    _historyBox.put('last_surah_id', surahId);
    _historyBox.put('last_position', positionInSeconds);
  }

  int? getLastPlayedSurahId() => _historyBox.get('last_surah_id');
  int? getLastPlayedPosition() => _historyBox.get('last_position');
}
