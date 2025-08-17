import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';

import 'aes.dart';
import 'crypto_utils.dart';

/// AES-256 key transform using parallel isolates.
abstract final class KeyEncryptorAes {
  /// Encrypts [data] (32 bytes) with [aes] for [rounds], returns SHA-256 hash.
  static Future<List<int>> transform({
    required Aes256 aes,
    required List<int> data,
    required int rounds,
  }) async {
    assert(data.length == 32, 'AES transform expects 32-byte input');

    if (rounds <= 0) {
      return sha256.convert(data).bytes;
    }

    Future<Uint8List> runBlock({required Uint8List block}) {
      return Isolate.run(() {
        aes.transformBlock(data: block, rounds: rounds);
        return block;
      });
    }

    final results = await Future.wait([
      runBlock(block: Uint8List.fromList(data.slice(0, 16))),
      runBlock(block: Uint8List.fromList(data.slice(16, 32))),
    ]);

    final result = results[0] + results[1];
    CryptoUtils.wipeData(results[0]);
    CryptoUtils.wipeData(results[1]);

    final hash = sha256.convert(result);
    CryptoUtils.wipeData(result);

    return hash.bytes;
  }
}
