import 'dart:typed_data';

import 'stream_cipher.dart';

/// ChaCha20 stream cipher (RFC 7539).
///
/// Subclasses provide concrete implementations (pure Dart, native FFI).
abstract class ChaCha20 extends StreamCipher {
  /// Encrypts or decrypts [data] with the given 12-byte [nonce].
  ///
  /// ChaCha20 is symmetric: encrypt and decrypt are the same XOR operation.
  @override
  Uint8List transform({
    required Uint8List data,
    required Uint8List nonce,
    int counter = 0,
  });
}
