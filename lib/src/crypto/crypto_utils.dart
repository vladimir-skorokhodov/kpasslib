import 'dart:math';
import 'dart:typed_data';

/// Encryption utility functions
abstract final class CryptoUtils {
  static const _byteRange = 1 << 8;

  /// Overwrites the [data] buffer with random bytes.
  static wipeData(List<int>? data) {
    data?.setAll(0, randomBytes(data.length));
  }

  /// Generates random bytes with requested [length].
  static Uint8List randomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = random.nextInt(_byteRange);
    }
    return bytes;
  }

  /// Returns result of XOR applied to [data] with [salt].
  static List<int> transformXor({
    required List<int> data,
    required List<int> salt,
  }) =>
      List.generate(data.length, (i) => data[i] ^ salt[i % salt.length]);
}
