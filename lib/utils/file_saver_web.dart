import 'dart:convert';
import 'package:web/web.dart' as web;
import 'package:archive/archive.dart';

Future<String?> saveFileImpl(List<int> bytes, String fileName) async {
  final base64Data = base64Encode(bytes);
  final uri = 'data:application/octet-stream;base64,$base64Data';
  
  final anchor = web.HTMLAnchorElement()
    ..href = uri
    ..download = fileName;
    
  anchor.click();
  return 'Web download triggered';
}

Future<String?> saveMultipleFilesImpl(List<List<int>> filesBytes, List<String> fileNames, String zipName) async {
  final archive = Archive();
  for (int i = 0; i < filesBytes.length; i++) {
    final file = ArchiveFile(fileNames[i], filesBytes[i].length, filesBytes[i]);
    archive.addFile(file);
  }

  final zipData = ZipEncoder().encode(archive);
  return await saveFileImpl(zipData, zipName);
}

Future<String?> saveAppCopyImpl(List<int> bytes, String fileName) async {
  return null;
}
