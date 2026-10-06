Future<String?> saveFileImpl(List<int> bytes, String fileName) async {
  throw UnsupportedError('Cannot save file on this platform');
}

Future<String?> saveMultipleFilesImpl(List<List<int>> filesBytes, List<String> fileNames, String zipName) async {
  throw UnsupportedError('Cannot save multiple files on this platform');
}

Future<String?> saveAppCopyImpl(List<int> bytes, String fileName) async {
  return null;
}
