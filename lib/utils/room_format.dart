/// Normalizes room text: trims whitespace and maps placeholders for
/// "no room" ("--", "-", empty) to null so they never persist in the
/// database or render in the UI. A raw "--" reads as noise on widgets and
/// in tiles; the ITU catalog emits "-" for unassigned rooms and users type
/// "--" as a placeholder, so both spellings (plus surrounding whitespace)
/// count as absent. En/em dashes ("–", "—") are the same placeholder
/// typed with a different key.
String? cleanRoom(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty ||
      text == '--' ||
      text == '-' ||
      text == '–' ||
      text == '—') {
    return null;
  }
  return text;
}
