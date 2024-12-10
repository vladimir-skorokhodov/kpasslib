import 'package:kpasslib/kpasslib.dart';
import 'package:kpasslib/src/crypto/hashed_block_transform.dart';
import 'package:test/test.dart';

void main() {
  group('HashedBlockTransform unit tests', () {
    test('decrypts and encrypts data', () {
      const src = [1, 2, 3, 4, 5];
      final enc = HashedBlockTransform.encrypt(src);
      final dec = HashedBlockTransform.decrypt(enc);
      expect(dec, src);
    });

    test('decrypts several blocks', () {
      final src = List<int>.generate(2 * DataSize.mebi + 2, (i) => i % 256);
      final enc = HashedBlockTransform.encrypt(src);
      final dec = HashedBlockTransform.decrypt(enc);
      expect(dec, src);
    });

    test('throws error for invalid hash block', () {
      const src = [1, 2, 3, 4, 5];
      final enc = HashedBlockTransform.encrypt(src);
      enc[4] = 0;

      expect(
          () => HashedBlockTransform.decrypt(enc),
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('invalid block hash'))));
    });
  });
}
