import 'package:convert/convert.dart';
import 'package:kpasslib/kpasslib.dart';
import 'package:kpasslib/src/crypto/protect_salt_generator.dart';
import 'package:test/test.dart';

void main() {
  group('ProtectSaltGenerator unit tests', () {
    test('generates random sequences with Salsa20', () {
      final gen = ProtectSaltGenerator.fromKey(
          key: [1, 2, 3], algorithm: CrsAlgorithm.salsa20);
      var bytes = gen.getSalt(0);
      expect(bytes.length, 0);
      bytes = gen.getSalt(10);
      expect(hex.encode(bytes), 'ab597831cbb24180dc0e');
      bytes = gen.getSalt(10);
      expect(hex.encode(bytes), '2c94ca5c18ea9534bc72');
      bytes = gen.getSalt(20);
      expect(hex.encode(bytes), '8ca54128a3549e2791af8ed6c61d184ca9fcd8fc');
    });

    test('generates random sequences with ChaCha20', () {
      final gen = ProtectSaltGenerator.fromKey(
          key: [1, 2, 3], algorithm: CrsAlgorithm.chaCha20);
      var bytes = gen.getSalt(0);
      expect(bytes.length, 0);
      bytes = gen.getSalt(10);
      expect(hex.encode(bytes), '89422fee6d8124ddae6d');
      bytes = gen.getSalt(10);
      expect(hex.encode(bytes), '0482d18192b16b16d1ce');
      bytes = gen.getSalt(20);
      expect(hex.encode(bytes), '2947815068cd058840a09b2d4aa9cc5d0c2e0fa1');
    });

    test('fails if the algorithm is not supported', () {
      expect(
          () => ProtectSaltGenerator.fromKey(
              key: [1, 2, 3], algorithm: CrsAlgorithm.none),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('crsAlgorithm'))));
    });
  });
}
