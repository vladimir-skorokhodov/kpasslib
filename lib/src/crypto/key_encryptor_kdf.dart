import 'dart:convert';
import 'dart:typed_data';

import 'package:kpasslib/kpasslib.dart';

import '../utils/parameters_map.dart';
import 'argon2.dart';
import 'key_encryptor_aes.dart';

/// KDF encryption functions
abstract final class KeyEncryptorKdf {
  static const int _saltLength = 32;
  static const int _minParallelism = 1;
  static const int _minIterations = 1;
  static const int _minMemory = 1;
  static const int _minRounds = 1;

  /// Returns encrypted [data].
  /// [data] must not be empty. For Argon2 and AES KDF, salt must be 32 bytes.
  static Future<List<int>> encrypt({
    required List<int> data,
    required ParametersMap parameters,
  }) async {
    final uuid = parameters.get('\$UUID');

    if (uuid is! List<int>) {
      throw FileCorruptedError('no kdf uuid');
    }

    final kdfUuid = base64.encode(uuid);

    return switch (kdfUuid) {
      KdfId.argon2d => _encryptArgon2(data, parameters, Argon2Type.argon2d),
      KdfId.argon2id => _encryptArgon2(data, parameters, Argon2Type.argon2id),
      KdfId.aes => _transformAes(data, parameters),
      _ => throw UnsupportedValueError('unknown KDF type')
    };
  }

  static Uint8List _encryptArgon2(
    List<int> data,
    ParametersMap kdfParams,
    Argon2Type argon2type,
  ) {
    final salt = kdfParams.get('S');

    if (salt is! List<int> || salt.length != _saltLength) {
      throw FileCorruptedError('bad argon2 salt');
    }

    final parallelism = kdfParams.get('P');
    if (parallelism is! int || parallelism < _minParallelism) {
      throw FileCorruptedError('bad argon2 parallelism');
    }

    final iterations = kdfParams.get('I');
    if (iterations is! int || iterations < _minIterations) {
      throw FileCorruptedError('bad argon2 iterations');
    }

    final memory = kdfParams.get('M');
    if (memory is! int || memory < _minMemory || memory % DataSize.kibi != 0) {
      throw FileCorruptedError('bad argon2 memory');
    }

    final v = kdfParams.get('V');
    final version = Argon2Version.values.firstWhere(
      (version) => version.value == v,
      orElse: () => throw UnsupportedValueError('argon2 version'),
    );

    if (kdfParams.get('K') != null) {
      throw UnsupportedValueError('argon2 secret key');
    }

    if (kdfParams.get('A') != null) {
      throw UnsupportedValueError('argon2 assoc data');
    }

    return Crypto.engine
        .createArgon2(
          type: argon2type,
          version: version,
          parallelism: parallelism,
          memorySizeKB: memory ~/ DataSize.kibi,
          iterations: iterations,
          salt: salt,
        )
        .convert(data);
  }

  static Future<List<int>> _transformAes(
      List<int> data, ParametersMap kdfParams) {
    final salt = kdfParams.get('S');
    if (salt is! List<int> || salt.length != _saltLength) {
      throw FileCorruptedError('bad aes salt');
    }

    final rounds = kdfParams.get('R');
    if (rounds is! int || rounds < _minRounds) {
      throw FileCorruptedError('bad aes rounds');
    }

    return KeyEncryptorAes.transform(
      aes: Crypto.engine.createAes256(key: Uint8List.fromList(salt)),
      data: Uint8List.fromList(data),
      rounds: rounds,
    );
  }
}
