import 'dart:typed_data';

import '../argon2.dart';
import '../crypto_engine.dart';
import 'aes256_dart.dart';
import 'argon2_dart.dart';
import 'chacha20_dart.dart';
import 'salsa20_dart.dart';

/// Default [CryptoEngine] using pure Dart implementations.
class CryptoDart extends CryptoEngine {
  @override
  Aes256Dart createAes256({required Uint8List key}) => Aes256Dart(key: key);

  @override
  ChaCha20Dart createChaCha20({required Uint8List key}) =>
      ChaCha20Dart(key: key);

  @override
  Salsa20Dart createSalsa20({required Uint8List key}) => Salsa20Dart(key: key);

  @override
  Argon2Dart createArgon2({
    Argon2Type type = Argon2Type.argon2id,
    Argon2Version version = Argon2Version.v13,
    required int parallelism,
    required int memorySizeKB,
    required int iterations,
    required List<int> salt,
  }) {
    return Argon2Dart(
      type: type,
      version: version,
      parallelism: parallelism,
      memorySizeKB: memorySizeKB,
      iterations: iterations,
      salt: salt,
    );
  }
}
