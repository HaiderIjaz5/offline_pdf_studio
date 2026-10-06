import 'dart:convert';
import 'dart:io' as java_io;
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyTheme = 'theme_mode';
  static const String _keyReviewCount = 'review_count';
  static const String _keyHasReviewed = 'has_reviewed';
  static const String _keyRecentFiles = 'recent_files';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<String> getThemeMode() async {
    final prefs = await _prefs;
    return prefs.getString(_keyTheme) ?? 'system';
  }

  static Future<void> setThemeMode(String mode) async {
    final prefs = await _prefs;
    await prefs.setString(_keyTheme, mode);
  }

  static Future<bool> incrementAndCheckReview() async {
    final prefs = await _prefs;
    if (prefs.getBool(_keyHasReviewed) ?? false) return false;
    
    int count = (prefs.getInt(_keyReviewCount) ?? 0) + 1;
    await prefs.setInt(_keyReviewCount, count);
    
    if (count >= 3) {
      await prefs.setBool(_keyHasReviewed, true);
      return true;
    }
    return false;
  }

  static Future<void> addRecentFile(String fileName, String path, String operation) async {
    final prefs = await _prefs;
    List<String> recents = prefs.getStringList(_keyRecentFiles) ?? [];
    
    final newEntry = jsonEncode({
      'fileName': fileName,
      'path': path,
      'operation': operation,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    recents.removeWhere((item) {
      final decoded = jsonDecode(item);
      return decoded['path'] == path;
    });
    
    recents.insert(0, newEntry);
    if (recents.length > 20) {
      recents = recents.sublist(0, 20);
    }
    
    await prefs.setStringList(_keyRecentFiles, recents);
  }

  static Future<List<Map<String, dynamic>>> getRecentFiles() async {
    final prefs = await _prefs;
    final List<String> recents = prefs.getStringList(_keyRecentFiles) ?? [];
    return recents.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
  }

  static Future<void> removeRecentFile(String path) async {
    final prefs = await _prefs;
    List<String> recents = prefs.getStringList(_keyRecentFiles) ?? [];
    recents.removeWhere((item) {
      final decoded = jsonDecode(item);
      return decoded['path'] == path;
    });
    await prefs.setStringList(_keyRecentFiles, recents);
    try {
      final file = java_io.File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
