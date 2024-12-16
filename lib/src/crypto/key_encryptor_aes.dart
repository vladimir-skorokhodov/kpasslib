import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

import 'crypto_utils.dart';

/// AES encryption function
abstract final class KeyEncryptorAes {
  /// Returns encrypted or decrypted [data].
  static List<int> transform({
    required List<int> data,
    required List<int> seed,
    required int rounds,
  }) {
    final aes = AESEngine()
      ..init(
        true,
        KeyParameter(Uint8List.fromList(seed)),
      );

    final result = Uint8List.fromList(data);
    for (var i = 0; i < rounds; i++) {
      aes.processBlock(result, 0, result, 0);
      aes.processBlock(result, aes.blockSize, result, aes.blockSize);
    }

    final hash = sha256.convert(result);
    CryptoUtils.wipeData(result);
    return hash.bytes;
  }
}
