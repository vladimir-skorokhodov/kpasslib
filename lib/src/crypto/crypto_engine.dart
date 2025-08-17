import 'dart:typed_data';

import 'aes.dart';
import 'argon2.dart';
import 'chacha20.dart';
import 'dart/crypto_dart.dart';
import 'salsa20.dart';

/// Global crypto configuration.
///
/// Set the global engine before calling KdbxDatabase.fromBytes or KdbxDatabase.save.
abstract final class Crypto {
  /// The global [CryptoEngine] instance. Defaults to [CryptoDart].
  static CryptoEngine engine = CryptoDart();
}

/// Factory for cryptographic algorithm instances.
///
/// Subclass to provide alternative implementations (e.g. native FFI).
abstract class CryptoEngine {
  /// Creates an [Aes256] cipher from a 32-byte [key].
  Aes256 createAes256({required Uint8List key});

  /// Creates a [ChaCha20] cipher from a 32-byte [key].
  ChaCha20 createChaCha20({required Uint8List key});

  /// Creates a [Salsa20] cipher from a 32-byte [key].
  Salsa20 createSalsa20({required Uint8List key});

  /// Creates an [Argon2] instance for native or Dart-backed hashing.
  Argon2 createArgon2({
    Argon2Type type,
    Argon2Version version,
    required int parallelism,
    required int memorySizeKB,
    required int iterations,
    required List<int> salt,
  });
}
