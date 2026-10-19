import 'package:chronicle/utils/room_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cleanRoom', () {
    test('maps absent markers to null', () {
      expect(cleanRoom(null), isNull);
      expect(cleanRoom(''), isNull);
      expect(cleanRoom('   '), isNull);
      expect(cleanRoom('--'), isNull);
      expect(cleanRoom(' -- '), isNull);
      expect(cleanRoom('-'), isNull);
      expect(cleanRoom(' - '), isNull);
    });

    test('keeps real rooms trimmed', () {
      expect(cleanRoom('C-K3-08[60]'), 'C-K3-08[60]');
      expect(cleanRoom('  Room 101  '), 'Room 101');
      expect(cleanRoom('A-Z04'), 'A-Z04');
    });

    test('does not strip room-like text containing dashes', () {
      expect(cleanRoom('C-K2-09'), 'C-K2-09');
      expect(cleanRoom('-- A'), '-- A');
    });
  });
}
