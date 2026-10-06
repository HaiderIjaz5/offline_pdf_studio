import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_io.dart';

class FileSaver {
  static Future<String?> saveFile(List<int> bytes, String fileName) async {
    return saveFileImpl(bytes, fileName);
  }

  static Future<String?> saveMultipleFiles(List<List<int>> filesBytes, List<String> fileNames, String zipName) async {
    return saveMultipleFilesImpl(filesBytes, fileNames, zipName);
  }

  static Future<String?> saveAppCopy(List<int> bytes, String fileName) async {
    return saveAppCopyImpl(bytes, fileName);
  }
}
