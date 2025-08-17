import 'package:collection/collection.dart';
import 'package:kpasslib/src/crypto/crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  group('CryptoUtils unit tests', () {
    test('Checks wipeData method', () {
      final buffer = CryptoUtils.randomBytes(5);
      final backup = List.from(buffer);
      CryptoUtils.wipeData(buffer);
      expect(ListEquality().equals(buffer, backup), false);
    });

    test('Checks bytes randomizer', () {
      final bytes1 = CryptoUtils.randomBytes(100);
      final bytes2 = CryptoUtils.randomBytes(100);
      expect(ListEquality().equals(bytes1, bytes2), false);
    });

    test('Checks simple transformation', () {
      final data = CryptoUtils.randomBytes(100);
      final salt = CryptoUtils.randomBytes(100);
      final encoded = CryptoUtils.transformXor(data: data, salt: salt);
      expect(ListEquality().equals(encoded, data), false);

      final decoded = CryptoUtils.transformXor(data: encoded, salt: salt);
      expect(decoded, data);
    });
  });
}
