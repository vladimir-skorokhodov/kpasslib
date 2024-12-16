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

    test('Checks AES transformation', () async {
      final data = CryptoUtils.randomBytes(16);
      final key = CryptoUtils.randomBytes(32);
      final iv = CryptoUtils.randomBytes(16);
      final encoded = await CryptoUtils.transformAes(
        data: data,
        key: key,
        iv: iv,
        encrypt: true,
      );
      expect(ListEquality().equals(encoded, data), false);

      final decoded = await CryptoUtils.transformAes(
        data: encoded,
        key: key,
        iv: iv,
        encrypt: false,
      );
      expect(decoded, data);
    });

    test('Checks ChaCha20 transformation', () async {
      final data = CryptoUtils.randomBytes(32);
      final key = CryptoUtils.randomBytes(32);
      final iv = CryptoUtils.randomBytes(12);
      final encoded = await CryptoUtils.transformChaCha20(
        data: data,
        key: key,
        iv: iv,
      );
      expect(ListEquality().equals(encoded, data), false);

      final decoded = await CryptoUtils.transformChaCha20(
        data: encoded,
        key: key,
        iv: iv,
      );
      expect(decoded, data);
    });
  });
}
