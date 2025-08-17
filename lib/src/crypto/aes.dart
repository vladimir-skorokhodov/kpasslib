import 'dart:typed_data';

/// AES-256 block cipher (FIPS 197).
///
/// Subclasses provide concrete encryption logic via [transformBlock].
abstract class Aes256 {
  /// Encrypts the first 16 bytes of [data] in place, [rounds] times.
  void transformBlock({required Uint8List data, required int rounds});

  /// Encrypts [data] using AES-256-CBC.
  /// If [padding] is true (default), applies PKCS7 padding.
  Uint8List encryptCbc({
    required Uint8List data,
    required Uint8List iv,
    bool padding = true,
  });

  /// Decrypts [data] using AES-256-CBC.
  /// If [padding] is true (default), strips PKCS7 padding.
  Uint8List decryptCbc({
    required Uint8List data,
    required Uint8List iv,
    bool padding = true,
  });
}
