class Surah {
  final int id; // Surah Number (1 - 114)
  final String nameArabic;
  final String nameEnglish;
  final String transliteration;
  final String revelationType; // Meccan or Medinan
  final Duration audioDuration;
  final String audioAssetPath;

  const Surah({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.transliteration,
    required this.revelationType,
    required this.audioDuration,
    required this.audioAssetPath,
  });

  // A helper method for the Search functionality
  // Returns true if the query matches the English name, Arabic name, or Surah number
  bool matchesSearch(String query) {
    final lowerCaseQuery = query.toLowerCase();
    return nameEnglish.toLowerCase().contains(lowerCaseQuery) ||
        transliteration.toLowerCase().contains(lowerCaseQuery) ||
        nameArabic.contains(lowerCaseQuery) ||
        id.toString() == query;
  }

  // Factory constructor for potential JSON parsing
  // Useful if you decide to load the 114 Surah metadata from a local JSON file
  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      id: json['id'] as int,
      nameArabic: json['name_arabic'] as String,
      nameEnglish: json['name_english'] as String,
      transliteration: json['transliteration'] as String,
      revelationType: json['revelation_type'] as String,
      // Assuming your JSON provides duration in seconds
      audioDuration: Duration(seconds: json['duration_seconds'] as int),
      audioAssetPath: 'assets/audio/${json['id']}.mp3',
    );
  }
}
