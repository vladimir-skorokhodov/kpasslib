import 'package:kpasslib/kpasslib.dart';
import 'package:test/test.dart';

void main() {
  group('UUID unit tests', () {
    test('creates uuid from 16 bytes array', () {
      final uuid =
          KdbxUuid.fromBytes([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1, 2, 3, 4, 5, 6]);
      expect(uuid.string, 'AQIDBAUGBwgJCgECAwQFBg==');
    });

    test('creates uuid base64 string', () {
      final uuid = KdbxUuid.fromString('AQIDBAUGBwgJCgECAwQFBg==');
      expect(uuid.string, 'AQIDBAUGBwgJCgECAwQFBg==');
    });

    test('throws an error for less than 16 bytes', () {
      expect(
          () => KdbxUuid.fromBytes([123]),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('bad UUID length'))));
    });

    test('creates empty uuid from empty bytes', () {
      final uuid = KdbxUuid.fromBytes([]);
      expect(uuid != KdbxUuid.zero, true);
    });

    test('sets empty property for empty uuid', () {
      final uuid = KdbxUuid.fromBytes(List<int>.filled(16, 0));
      expect(uuid, KdbxUuid.zero);
    });

    test('returns bytes in bytes getter', () {
      final bytes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1, 2, 3, 4, 5, 6];
      final uuid = KdbxUuid.fromBytes(bytes);
      expect(uuid.bytes, bytes);
    });

    test('generates random uuid', () {
      final uuid = KdbxUuid.random();
      expect(uuid != KdbxUuid.zero, true);
    });

    test('checks equality', () {
      final uuid =
          KdbxUuid.fromBytes([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1, 2, 3, 4, 5, 6]);
      expect(uuid, KdbxUuid.fromString('AQIDBAUGBwgJCgECAwQFBg=='));
      expect(uuid != KdbxUuid.fromBytes([]), true);
      expect(uuid != KdbxUuid.fromString(''), true);
    });
  });
}
