import 'dart:ffi';
import 'dart:typed_data';

import '../argon2.dart';
import '../crypto_engine.dart';
import 'aes256_ffi.dart';
import 'argon2_ffi.dart';
import 'chacha20_ffi.dart';
import 'salsa20_ffi.dart';

/// [CryptoEngine] backed by a native C library.
///
/// Uses FFI to call hardware-accelerated AES (ARM Crypto Extensions)
/// or optimized software fallback.
///
/// Example:
/// ```dart
/// // iOS (statically linked)
/// Crypto.engine = CryptoFfi(DynamicLibrary.process());
/// // Android
/// Crypto.engine = CryptoFfi(DynamicLibrary.open('libkreepto.so'));
/// // macOS
/// Crypto.engine = CryptoFfi(DynamicLibrary.open('/path/to/libkreepto.dylib'));
/// ```
class CryptoFfi extends CryptoEngine {
  final Aes256TransformBlockDart _aes256TransformBlock;
  final Aes256CbcDart _encryptCbc;
  final Aes256CbcDart _decryptCbc;
  final ChaCha20TransformDart _chacha20Transform;
  final Salsa20TransformDart _salsa20Transform;
  final Argon2HashDart _argon2Hash;

  /// Creates a [CryptoFfi] engine from an already-loaded [DynamicLibrary].
  CryptoFfi(DynamicLibrary lib)
      : _aes256TransformBlock =
            lib.lookupFunction<Aes256TransformBlockC, Aes256TransformBlockDart>(
                'aes256_transform_block'),
        _encryptCbc =
            lib.lookupFunction<Aes256CbcC, Aes256CbcDart>('aes256_encrypt_cbc'),
        _decryptCbc =
            lib.lookupFunction<Aes256CbcC, Aes256CbcDart>('aes256_decrypt_cbc'),
        _chacha20Transform =
            lib.lookupFunction<ChaCha20TransformC, ChaCha20TransformDart>(
                'chacha20_transform'),
        _salsa20Transform =
            lib.lookupFunction<Salsa20TransformC, Salsa20TransformDart>(
                'salsa20_transform'),
        _argon2Hash =
            lib.lookupFunction<Argon2HashC, Argon2HashDart>('argon2_hash');

  @override
  Aes256Ffi createAes256({required Uint8List key}) => Aes256Ffi(
        transformFn: _aes256TransformBlock,
        encryptCbcFn: _encryptCbc,
        decryptCbcFn: _decryptCbc,
        key: key,
      );

  @override
  ChaCha20Ffi createChaCha20({required Uint8List key}) =>
      ChaCha20Ffi(transformFn: _chacha20Transform, key: key);

  @override
  Salsa20Ffi createSalsa20({required Uint8List key}) =>
      Salsa20Ffi(transformFn: _salsa20Transform, key: key);

  @override
  Argon2Ffi createArgon2({
    Argon2Type type = Argon2Type.argon2id,
    Argon2Version version = Argon2Version.v13,
    required int parallelism,
    required int memorySizeKB,
    required int iterations,
    required List<int> salt,
  }) {
    return Argon2Ffi(
      hashFn: _argon2Hash,
      type: type,
      version: version,
      parallelism: parallelism,
      memorySizeKB: memorySizeKB,
      iterations: iterations,
      salt: salt,
    );
  }
}
