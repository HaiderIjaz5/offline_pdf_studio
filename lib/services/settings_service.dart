import 'dart:convert';
import 'dart:io' as java_io;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
    
    final validRecents = <String>[];
    final validParsed = <Map<String, dynamic>>[];
    
    for (final item in recents) {
      final decoded = jsonDecode(item) as Map<String, dynamic>;
      final path = (decoded['path'] as String).toLowerCase();
      if (path.endsWith('.pdf') || path.endsWith('.png') || path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.zip')) {
        validRecents.add(item);
        validParsed.add(decoded);
      }
    }
    
    if (validRecents.length != recents.length) {
      await prefs.setStringList(_keyRecentFiles, validRecents);
    }
    
    return validParsed;
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
      final dir = await getApplicationDocumentsDirectory();
      final privateFolder = java_io.Directory('${dir.path}/OfflinePDFStudio');
      final file = java_io.File(path);
      if (p.isWithin(privateFolder.path, file.path) && await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
