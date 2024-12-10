import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Encryption utility functions
abstract final class CryptoUtils {
  static const _maxByte = 2 ^ 8;

  /// Overwrites the [data] buffer.
  static wipeData(List<int>? data) {
    if (data == null || data.isEmpty) {
      return;
    }

    final random = Random.secure();
    for (int i = 0; i < data.length; ++i) {
      data[i] = random.nextInt(2 ^ 32);
    }
  }

  /// Generates random list of bytes with requested [length].
  static List<int> randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (i) => random.nextInt(_maxByte));
  }

  /// Returns result of XOR applied to [data] with [salt].
  static List<int> transformXor({
    required List<int> data,
    required List<int> salt,
  }) =>
      List<int>.generate(data.length, (i) => data[i] ^ salt[i]);

  /// Returns result of [data] transformation with AES algorithm.
  static List<int> transformAes({
    required List<int> data,
    required List<int> key,
    required List<int> iv,
    bool encrypt = true,
  }) {
    final cbc = CBCBlockCipher(AESEngine())
      ..init(
        encrypt,
        ParametersWithIV(
          KeyParameter(Uint8List.fromList(key)),
          Uint8List.fromList(iv),
        ),
      );

    final pad = -data.length % cbc.blockSize;
    final inp = Uint8List.fromList(data + List.filled(pad, pad));
    final out = Uint8List(inp.length);

    var offset = 0;
    while (offset < inp.length) {
      offset += cbc.processBlock(inp, offset, out, offset);
    }

    return out;
  }

  /// Returns result of [data] transformation with ChaCha20 algorithm.
  static List<int> transformChaCha20({
    required List<int> data,
    required List<int> key,
    required List<int> iv,
  }) {
    final chacha = ChaCha7539Engine()
      ..init(
        true,
        ParametersWithIV(
          KeyParameter(Uint8List.fromList(key)),
          Uint8List.fromList(iv),
        ),
      );

    return chacha.process(Uint8List.fromList(data));
  }
}
