import 'dart:typed_data';

import 'stream_cipher.dart';

/// Salsa20 stream cipher.
abstract class Salsa20 extends StreamCipher {
  /// Encrypts or decrypts [data] using an 8-byte [nonce].
  @override
  Uint8List transform({
    required Uint8List data,
    required Uint8List nonce,
    int counter = 0,
  });
}
