import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/helpers.dart' as ch;

/// Encryption utility functions
abstract final class CryptoUtils {
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
  static List<int> randomBytes(int length) => ch.randomBytes(
        length,
        random: SecureRandom.fast,
      );

  /// Returns result of XOR applied to [data] with [salt].
  static List<int> transformXor({
    required List<int> data,
    required List<int> salt,
  }) {
    final saltLength = salt.length;
    return List<int>.generate(
        data.length, (i) => data[i] ^ salt[i % saltLength]);
  }

  /// Returns result of [data] transformation with AES algorithm.
  static Future<List<int>> transformAes({
    required List<int> data,
    required List<int> key,
    required List<int> iv,
    bool encrypt = true,
  }) async {
    final cbc = AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty);
    final secretKey = await cbc.newSecretKeyFromBytes(key);

    if (encrypt) {
      final box = await cbc.encrypt(
        data,
        secretKey: secretKey,
        nonce: iv,
      );
      return box.cipherText;
    } else {
      return await cbc.decrypt(
        SecretBox(data, nonce: iv, mac: Mac.empty),
        secretKey: secretKey,
      );
    }
  }

  /// Returns result of [data] transformation with ChaCha20 algorithm.
  static Future<List<int>> transformChaCha20({
    required List<int> data,
    required List<int> key,
    required List<int> iv,
  }) async {
    final chacha = Chacha20(macAlgorithm: MacAlgorithm.empty);
    final secretKey = await chacha.newSecretKeyFromBytes(key);
    final box = await chacha.encrypt(
      data,
      secretKey: secretKey,
      nonce: iv,
    );

    return box.cipherText;
  }
}
