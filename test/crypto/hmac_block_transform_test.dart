import 'package:convert/convert.dart';
import 'package:kpasslib/kpasslib.dart';
import 'package:kpasslib/src/crypto/hmac_block_transform.dart';
import 'package:test/test.dart';

void main() {
  group('HmacBlockTransform unit tests', () {
    final key = hex.decode(
        '1f5c3ef76d43e72ee2c5216c36187c799b153cab3d0cb63a6f3ecccc2627f535');
    test('decrypts and encrypts data', () {
      const src = [1, 2, 3, 4, 5];
      final enc = HmacBlockTransform.encrypt(data: src, key: key);
      final dec = HmacBlockTransform.decrypt(data: enc, key: key);
      expect(dec, src);
    });

    test('decrypts several blocks', () {
      final src = List<int>.generate(2 * DataSize.mebi + 2, (i) => i % 256);
      final enc = HmacBlockTransform.encrypt(data: src, key: key);
      final dec = HmacBlockTransform.decrypt(data: enc, key: key);
      expect(dec, src);
    });

    test('throws error for invalid hash block', () {
      const src = [1, 2, 3, 4, 5];
      final enc = HmacBlockTransform.encrypt(data: src, key: key);
      enc[4] = 0;

      expect(
        () => HmacBlockTransform.decrypt(data: enc, key: key),
        throwsA(
          predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('invalid block hash')),
        ),
      );
    });
  });
}
