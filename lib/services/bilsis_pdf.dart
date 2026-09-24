import 'dart:typed_data';

import 'package:pdf_document/pdf_document.dart';
import 'package:pdf_graphics/pdf_graphics.dart';

import 'bilsis.dart';

/// Extracts positioned words from a Bilsis schedule PDF for
/// [parseBilsisPages]. Pure Dart (pdf_document/pdf_graphics), so it runs
/// on Android and Linux with no native plugins.
///
/// Pages beyond [maxPages] are ignored and oversized files rejected, so a
/// stray multi-hundred-page PDF cannot stall the import flow.
Future<List<List<BilsisWord>>> extractBilsisWords(
  Uint8List bytes, {
  int maxPages = 12,
  int maxBytes = 15 * 1024 * 1024,
}) async {
  if (bytes.length > maxBytes) {
    throw const BilsisParseException('too-large');
  }
  final PdfDocument doc;
  try {
    doc = PdfDocument.open(bytes);
  } catch (e) {
    throw BilsisParseException('unreadable: $e');
  }
  final count = doc.pageCount.clamp(0, maxPages);
  if (count == 0) throw const BilsisParseException('no-pages');
  final pages = <List<BilsisWord>>[];
  for (var i = 0; i < count; i++) {
    final PdfPageText page;
    try {
      page = PdfTextExtractor.extract(doc, i);
    } catch (e) {
      throw BilsisParseException('page-$i: $e');
    }
    final words = <BilsisWord>[];
    for (final token in tokenizePageText(page)) {
      final text = token.text.trim();
      if (text.isEmpty) continue;
      final bounds = token.bounds;
      if (bounds == null) continue;
      words.add(
        BilsisWord(
          text: text,
          left: bounds.left,
          right: bounds.right,
          cy: (bounds.top + bounds.bottom) / 2,
        ),
      );
    }
    pages.add(words);
  }
  return pages;
}
