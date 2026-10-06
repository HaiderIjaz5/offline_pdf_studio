class PageParser {
  static List<int> parse(String input, int maxPage) {
    if (input.trim().isEmpty) {
      throw FormatException('Input cannot be empty.');
    }

    final Set<int> pages = {};
    final parts = input.split(',');

    for (var part in parts) {
      final token = part.trim();
      if (token.isEmpty) continue;

      if (RegExp(r'^\d+$').hasMatch(token)) {
        final page = int.parse(token);
        if (page < 1 || page > maxPage) {
          throw FormatException('Page $page does not exist. This PDF has $maxPage pages.');
        }
        pages.add(page);
      } else if (RegExp(r'^\d+\s*-\s*\d+$').hasMatch(token)) {
        final bounds = token.split('-');
        final start = int.parse(bounds[0].trim());
        final end = int.parse(bounds[1].trim());
        
        if (start < 1 || start > maxPage) {
          throw FormatException('Page $start does not exist. This PDF has $maxPage pages.');
        }
        if (end < 1 || end > maxPage) {
          throw FormatException('Page $end does not exist. This PDF has $maxPage pages.');
        }
        
        int step = start <= end ? 1 : -1;
        for (int i = start; start <= end ? i <= end : i >= end; i += step) {
          pages.add(i);
        }
      } else {
        throw FormatException('"$token" is not a valid page. Use formats like 3 or 1-3.');
      }
    }

    final sorted = pages.toList()..sort();
    return sorted;
  }
}
