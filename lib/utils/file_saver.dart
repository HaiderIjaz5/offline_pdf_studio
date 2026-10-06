import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_io.dart';

class FileSaver {
  static String _generateFileName(String defaultExt) {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'pdf_scanner_&_tools_offline_$timestamp$defaultExt';
  }

  static Future<String?> saveFile(List<int> bytes, String fileName) async {
    final ext = fileName.contains('.') ? '.${fileName.split('.').last}' : '.pdf';
    final newFileName = _generateFileName(ext);
    return saveFileImpl(bytes, newFileName);
  }

  static Future<String?> saveMultipleFiles(List<List<int>> filesBytes, List<String> fileNames, String zipName) async {
    final newZipName = _generateFileName('.zip');
    return saveMultipleFilesImpl(filesBytes, fileNames, newZipName);
  }

  static Future<String?> saveAppCopy(List<int> bytes, String fileName) async {
    return saveAppCopyImpl(bytes, fileName);
  }
}
