import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:path_provider/path_provider.dart';

class PdfService {
  static Future<Uint8List?> mergePdfs(List<String> filePaths, List<Uint8List> fileBytes) async {
    try {
      final int count = kIsWeb ? fileBytes.length : filePaths.length;
      if (count == 0) return null;

      if (kIsWeb) {
        // Web fallback using Syncfusion
        final PdfDocument document = PdfDocument();
        for (int i = 0; i < count; i++) {
          final PdfDocument loadedDocument = PdfDocument(inputBytes: fileBytes[i]);
          for (int j = 0; j < loadedDocument.pages.count; j++) {
            final PdfPage sourcePage = loadedDocument.pages[j];
            final PdfTemplate template = sourcePage.createTemplate();
            final PdfSection section = document.sections!.add();
            section.pageSettings.size = template.size;
            section.pageSettings.margins.all = 0;
            section.pages.add().graphics.drawPdfTemplate(template, const Offset(0, 0));
          }
          loadedDocument.dispose();
        }
        final List<int> bytes = document.saveSync();
        document.dispose();
        return Uint8List.fromList(bytes);
      }

      // Native platforms (Android, iOS, Windows, macOS) use pdf_combiner for zero formatting loss
      final Directory tempDir = await getTemporaryDirectory();
      final String outputPath = '${tempDir.path}/merged_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      final List<MergeInput> inputs = filePaths.map((path) => MergeInput.path(path)).toList();
      
      await PdfCombiner.mergeMultiplePDFs(
        inputs: inputs,
        outputPath: outputPath,
      );
      
      final File mergedFile = File(outputPath);
      final Uint8List mergedBytes = mergedFile.readAsBytesSync();
      
      // Clean up the temporary file
      try {
        mergedFile.deleteSync();
      } catch (_) {}
      
      return mergedBytes;
    } catch (e) {
      debugPrint('Error merging PDFs: $e');
      return null;
    }
  }

  /// Splits a PDF by extracting specific pages.
  static Future<Uint8List?> splitPdf(dynamic fileInput, List<int> pagesToExtract) async {
    try {
      PdfDocument document;
      if (kIsWeb) {
        document = PdfDocument(inputBytes: fileInput as Uint8List);
      } else {
        document = PdfDocument(inputBytes: File(fileInput as String).readAsBytesSync());
      }
      
      // Iterate backwards and remove pages that are NOT in the extraction list
      // This preserves the exact PDF format, text, and metadata, unlike drawing templates
      for (int i = document.pages.count - 1; i >= 0; i--) {
        if (!pagesToExtract.contains(i)) {
          document.pages.removeAt(i);
        }
      }
      
      final List<int> bytes = document.saveSync();
      document.dispose();
      
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error splitting PDF: $e');
      return null;
    }
  }

  /// Compresses a PDF to reduce its file size.
  static Future<Uint8List?> compressPdf(dynamic fileInput) async {
    try {
      PdfDocument document;
      if (kIsWeb) {
        document = PdfDocument(inputBytes: fileInput as Uint8List);
      } else {
        document = PdfDocument(inputBytes: File(fileInput as String).readAsBytesSync());
      }
      
      // Disable incremental updates and use stream to reduce file size
      document.fileStructure.incrementalUpdate = false;
      document.fileStructure.crossReferenceType = PdfCrossReferenceType.crossReferenceStream;
      
      // Syncfusion applies comprehensive compression to the document structure
      document.compressionLevel = PdfCompressionLevel.best;
      
      final List<int> bytes = document.saveSync();
      document.dispose();
      
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error compressing PDF: $e');
      return null;
    }
  }

  /// Converts a list of images into a single PDF document.
  static Future<Uint8List?> imagesToPdf(List<dynamic> imageInputs) async {
    try {
      final PdfDocument document = PdfDocument();
      document.pageSettings.margins.all = 0;
      
      for (var input in imageInputs) {
        Uint8List imageBytes;
        if (kIsWeb) {
          imageBytes = input as Uint8List;
        } else {
          imageBytes = File(input as String).readAsBytesSync();
        }
        
        final PdfBitmap pdfImage = PdfBitmap(imageBytes);
        final PdfPage page = document.pages.add();
        
        // Calculate proportional scale to fit within page bounds without stretching
        final double pageWidth = page.getClientSize().width;
        final double pageHeight = page.getClientSize().height;
        final double imageWidth = pdfImage.width.toDouble();
        final double imageHeight = pdfImage.height.toDouble();
        
        final double widthScale = pageWidth / imageWidth;
        final double heightScale = pageHeight / imageHeight;
        final double scale = widthScale < heightScale ? widthScale : heightScale;
        
        final double finalWidth = imageWidth * scale;
        final double finalHeight = imageHeight * scale;
        
        // Center the image on the page
        final double x = (pageWidth - finalWidth) / 2;
        final double y = (pageHeight - finalHeight) / 2;
        
        page.graphics.drawImage(
          pdfImage, 
          Rect.fromLTWH(x, y, finalWidth, finalHeight),
        );
      }
      
      final List<int> bytes = document.saveSync();
      document.dispose();
      
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error converting images to PDF: $e');
      return null;
    }
  }

  /// Extracts pages from a PDF as images.
  static Future<Uint8List?> renderPdfPageToImage(dynamic fileInput, int pageNumber) async {
    try {
      pdfx.PdfDocument document;
      if (kIsWeb) {
        document = await pdfx.PdfDocument.openData(fileInput as Uint8List);
      } else {
        document = await pdfx.PdfDocument.openFile(fileInput as String);
      }
      
      final page = await document.getPage(pageNumber);
      final pageImage = await page.render(
        width: page.width * 2.0, 
        height: page.height * 2.0,
        format: pdfx.PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );
      
      await page.close();
      await document.close();
      
      return pageImage?.bytes;
    } catch(e) {
      debugPrint('Error converting PDF to images: $e');
      return null;
    }
  }

  /// Extracts all pages from a PDF as images (PNG format).
  static Future<List<Uint8List>?> renderAllPdfPagesToImages(dynamic fileInput) async {
    try {
      pdfx.PdfDocument document;
      if (kIsWeb) {
        document = await pdfx.PdfDocument.openData(fileInput as Uint8List);
      } else {
        document = await pdfx.PdfDocument.openFile(fileInput as String);
      }
      
      final List<Uint8List> images = [];
      for (int i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);
        final pageImage = await page.render(
          width: page.width * 2.0, 
          height: page.height * 2.0,
          format: pdfx.PdfPageImageFormat.png,
          backgroundColor: '#FFFFFF',
        );
        if (pageImage?.bytes != null) {
          images.add(pageImage!.bytes);
        }
        await page.close();
      }
      
      await document.close();
      return images;
    } catch(e) {
      debugPrint('Error converting all PDF pages to images: $e');
      return null;
    }
  }

  static Future<int> getPageCount(dynamic fileInput) async {
    try {
      pdfx.PdfDocument document;
      if (kIsWeb) {
        document = await pdfx.PdfDocument.openData(fileInput as Uint8List);
      } else {
        document = await pdfx.PdfDocument.openFile(fileInput as String);
      }
      final count = document.pagesCount;
      await document.close();
      return count;
    } catch (e) {
      debugPrint('Error getting page count: $e');
      return 0;
    }
  }

  static Future<List<Uint8List>?> renderPdfPagesToImages(dynamic fileInput, List<int> pages) async {
    try {
      pdfx.PdfDocument document;
      if (kIsWeb) {
        document = await pdfx.PdfDocument.openData(fileInput as Uint8List);
      } else {
        document = await pdfx.PdfDocument.openFile(fileInput as String);
      }
      
      final List<Uint8List> images = [];
      for (final pageNumber in pages) {
        final page = await document.getPage(pageNumber);
        final pageImage = await page.render(
          width: page.width * 2.0, 
          height: page.height * 2.0,
          format: pdfx.PdfPageImageFormat.png,
          backgroundColor: '#FFFFFF',
        );
        if (pageImage?.bytes != null) {
          images.add(pageImage!.bytes);
        } else {
          throw Exception('Failed to render page $pageNumber');
        }
        await page.close();
      }
      
      await document.close();
      return images;
    } catch (e) {
      debugPrint('Error rendering PDF pages: $e');
      return null;
    }
  }

  /// Reorders pages in the PDF according to newOrder (list of 0-based indices).
  static Future<Uint8List?> reorderPages(dynamic fileInput, List<int> newOrder) async {
    try {
      PdfDocument document;
      if (kIsWeb) {
        document = PdfDocument(inputBytes: fileInput as Uint8List);
      } else {
        document = PdfDocument(inputBytes: File(fileInput as String).readAsBytesSync());
      }
      
      final PdfDocument newDocument = PdfDocument();
      for (int index in newOrder) {
        if (index >= 0 && index < document.pages.count) {
          final PdfPage sourcePage = document.pages[index];
          final PdfTemplate template = sourcePage.createTemplate();
          final PdfSection section = newDocument.sections!.add();
          section.pageSettings.size = template.size;
          section.pageSettings.margins.all = 0;
          section.pages.add().graphics.drawPdfTemplate(template, const Offset(0, 0));
        }
      }
      
      final List<int> bytes = newDocument.saveSync();
      document.dispose();
      newDocument.dispose();
      
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error reordering pages: $e');
      return null;
    }
  }

  /// Rotates specific pages in the PDF. rotations maps page index to angle (90, 180, 270).
  static Future<Uint8List?> rotatePages(dynamic fileInput, Map<int, int> rotations) async {
    try {
      PdfDocument document;
      if (kIsWeb) {
        document = PdfDocument(inputBytes: fileInput as Uint8List);
      } else {
        document = PdfDocument(inputBytes: File(fileInput as String).readAsBytesSync());
      }
      
      for (var entry in rotations.entries) {
        final int pageIndex = entry.key;
        final int angle = entry.value;
        if (pageIndex >= 0 && pageIndex < document.pages.count) {
          PdfPageRotateAngle rotation = PdfPageRotateAngle.rotateAngle0;
          if (angle == 90) rotation = PdfPageRotateAngle.rotateAngle90;
          else if (angle == 180) rotation = PdfPageRotateAngle.rotateAngle180;
          else if (angle == 270) rotation = PdfPageRotateAngle.rotateAngle270;
          document.pages[pageIndex].rotation = rotation;
        }
      }
      
      final List<int> bytes = document.saveSync();
      document.dispose();
      
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error rotating pages: $e');
      return null;
    }
  }

  /// Adds a watermark text, optionally adds page numbers to the footer.
  static Future<Uint8List?> addWatermarkAndPageNumbers(dynamic fileInput, {String? watermarkText, bool diagonal = true, bool addPageNumbers = false, List<int>? pages}) async {
    try {
      PdfDocument document;
      if (kIsWeb) {
        document = PdfDocument(inputBytes: fileInput as Uint8List);
      } else {
        document = PdfDocument(inputBytes: File(fileInput as String).readAsBytesSync());
      }
      
      final PdfFont watermarkFont = PdfStandardFont(PdfFontFamily.helvetica, 60);
      final PdfFont pageNumberFont = PdfStandardFont(PdfFontFamily.helvetica, 12);
      final PdfBrush watermarkBrush = PdfSolidBrush(PdfColor(128, 128, 128));
      final PdfBrush pageNumberBrush = PdfSolidBrush(PdfColor(0, 0, 0));

      for (int i = 0; i < document.pages.count; i++) {
        if (pages != null && !pages.contains(i + 1)) continue;

        final PdfPage page = document.pages[i];
        final Size pageSize = page.getClientSize();

        if (watermarkText != null && watermarkText.isNotEmpty) {
          page.graphics.save();
          page.graphics.setTransparency(0.25);
          
          final Size textSize = watermarkFont.measureString(watermarkText);
          double x = (pageSize.width - textSize.width) / 2;
          double y = (pageSize.height - textSize.height) / 2;

          if (diagonal) {
            page.graphics.translateTransform(pageSize.width / 2, pageSize.height / 2);
            page.graphics.rotateTransform(-45);
            page.graphics.drawString(watermarkText, watermarkFont, brush: watermarkBrush, bounds: Rect.fromLTWH(-textSize.width / 2, -textSize.height / 2, textSize.width, textSize.height));
          } else {
            page.graphics.drawString(watermarkText, watermarkFont, brush: watermarkBrush, bounds: Rect.fromLTWH(x, y, textSize.width, textSize.height));
          }
          page.graphics.restore();
        }

        if (addPageNumbers) {
          final String text = 'Page ${i + 1}';
          final Size textSize = pageNumberFont.measureString(text);
          page.graphics.drawString(text, pageNumberFont, brush: pageNumberBrush, bounds: Rect.fromLTWH((pageSize.width - textSize.width) / 2, pageSize.height - 20, textSize.width, textSize.height));
        }
      }
      
      final List<int> bytes = document.saveSync();
      document.dispose();
      
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error adding watermark/page numbers: $e');
      return null;
    }
  }

  /// Encrypts the PDF with a password using AES 256.
  static Future<Uint8List?> protectPdf(dynamic fileInput, String password) async {
    try {
      PdfDocument document;
      if (kIsWeb) {
        document = PdfDocument(inputBytes: fileInput as Uint8List);
      } else {
        document = PdfDocument(inputBytes: File(fileInput as String).readAsBytesSync());
      }
      
      PdfSecurity security = document.security;
      security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;
      security.userPassword = password;
      security.ownerPassword = password;
      
      final List<int> bytes = document.saveSync();
      document.dispose();
      
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error protecting PDF: $e');
      return null;
    }
  }

  /// Removes encryption from a PDF by providing the current password.
  static Future<Uint8List?> unlockPdf(dynamic fileInput, String password) async {
    try {
      PdfDocument document;
      if (kIsWeb) {
        document = PdfDocument(inputBytes: fileInput as Uint8List, password: password);
      } else {
        document = PdfDocument(inputBytes: File(fileInput as String).readAsBytesSync(), password: password);
      }
      
      // To completely remove security, we copy pages to a new document
      final PdfDocument newDocument = PdfDocument();
      for (int j = 0; j < document.pages.count; j++) {
        final PdfPage sourcePage = document.pages[j];
        final PdfTemplate template = sourcePage.createTemplate();
        final PdfSection section = newDocument.sections!.add();
        section.pageSettings.size = template.size;
        section.pageSettings.margins.all = 0;
        section.pages.add().graphics.drawPdfTemplate(template, const Offset(0, 0));
      }
      
      final List<int> bytes = newDocument.saveSync();
      document.dispose();
      newDocument.dispose();
      
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error unlocking PDF (wrong password or corrupted): $e');
      return null;
    }
  }

  static Future<Uint8List?> addSignature(dynamic fileInput, int pageIndex, Uint8List signatureBytes, {required double xFraction, required double yFraction, required double widthFraction, required double rotationDegrees}) async {
    try {
      PdfDocument document;
      if (kIsWeb) {
        document = PdfDocument(inputBytes: fileInput as Uint8List);
      } else {
        document = PdfDocument(inputBytes: File(fileInput as String).readAsBytesSync());
      }
      
      if (pageIndex >= 0 && pageIndex < document.pages.count) {
        final PdfPage page = document.pages[pageIndex];
        final PdfBitmap image = PdfBitmap(signatureBytes);
        
        final Size pageSize = page.getClientSize();
        
        final double width = pageSize.width * widthFraction;
        final double height = (image.height / image.width) * width;
        
        final double x = pageSize.width * xFraction;
        final double y = pageSize.height * yFraction;
        
        page.graphics.save();
        page.graphics.translateTransform(x + width / 2, y + height / 2);
        page.graphics.rotateTransform(rotationDegrees);
        page.graphics.drawImage(image, Rect.fromLTWH(-width / 2, -height / 2, width, height));
        page.graphics.restore();
      }
      
      final List<int> bytes = document.saveSync();
      document.dispose();
      
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error adding signature: $e');
      return null;
    }
  }

  /// Extracts textual content from the entire PDF document.
  static Future<String?> extractText(dynamic fileInput) async {
    try {
      PdfDocument document;
      if (kIsWeb) {
        document = PdfDocument(inputBytes: fileInput as Uint8List);
      } else {
        document = PdfDocument(inputBytes: File(fileInput as String).readAsBytesSync());
      }
      
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final StringBuffer buffer = StringBuffer();
      
      for (int i = 0; i < document.pages.count; i++) {
        buffer.writeln('--- Page ${i + 1} ---');
        final String text = extractor.extractText(startPageIndex: i, endPageIndex: i);
        if (text.trim().isEmpty) {
          buffer.writeln('No text found on page ${i + 1}');
        } else {
          buffer.writeln(text);
        }
        buffer.writeln();
      }
      
      document.dispose();
      return buffer.toString();
    } catch (e) {
      debugPrint('Error extracting text: $e');
      return null;
    }
  }
}