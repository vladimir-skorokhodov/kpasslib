import 'dart:typed_data';

/// Generic stream cipher abstraction.
///
/// This is the base interface for stream ciphers such as ChaCha20 and Salsa20.
abstract class StreamCipher {
  /// Encrypts or decrypts [data] with the given [nonce].
  ///
  /// [counter] is the initial block counter. It defaults to zero.
  Uint8List transform({
    required Uint8List data,
    required Uint8List nonce,
    int counter = 0,
  });

  /// 32-bit mask used to emulate unsigned 32-bit arithmetic.
  static const int mask = 0xFFFFFFFF;

  /// Rotate left over a 32-bit word.
  static int rotl(int value, int shift) =>
      ((value << shift) | (value >>> (32 - shift))) & mask;

  /// Load a 32-bit little-endian word from [bytes] at [offset].
  static int loadLE(Uint8List bytes, int offset) =>
      bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);

  /// Add two 32-bit words modulo 2^32.
  static int add32(int a, int b) => (a + b) & mask;

  /// Add two 32-bit words modulo 2^32 and rotate left.
  static int add32Rotl(int a, int b, int shift) => rotl(add32(a, b), shift);

  /// Shared streaming transform loop for stream ciphers.
  static Uint8List processStream({
    required Uint8List data,
    required Uint32List state,
    required void Function(Uint32List state, Uint32List out) generateBlock,
    required void Function(Uint32List state) incrementCounter,
  }) {
    final out = Uint8List(data.length);
    final block = Uint8List(64);
    final blockView = block.buffer.asUint32List();
    var offset = 0;

    while (offset < data.length) {
      generateBlock(state, blockView);
      final remaining = data.length - offset;
      final n = remaining < 64 ? remaining : 64;
      for (var i = 0; i < n; i++) {
        out[offset + i] = data[offset + i] ^ block[i];
      }
      offset += n;
      incrementCounter(state);
    }

    return out;
  }
}
