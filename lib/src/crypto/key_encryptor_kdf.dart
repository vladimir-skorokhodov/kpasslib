import 'dart:convert';

import 'package:hashlib/hashlib.dart' as hashlib;
import 'package:kpasslib/kpasslib.dart';

import '../utils/parameters_map.dart';
import 'key_encryptor_aes.dart';

/// KDF encryption functions
// TODO: define constants for magic numbers
abstract final class KeyEncryptorKdf {
  /// Returns encrypted [data].
  static List<int> encrypt({
    required List<int> data,
    required ParametersMap parameters,
  }) {
    final uuid = parameters.get('\$UUID');

    if (uuid is! List<int>) {
      throw FileCorruptedError('no kdf uuid');
    }

    final kdfUuid = base64.encode(uuid);

    return switch (kdfUuid) {
      KdfId.argon2d =>
        _encryptArgon2(data, parameters, hashlib.Argon2Type.argon2d),
      KdfId.argon2id =>
        _encryptArgon2(data, parameters, hashlib.Argon2Type.argon2id),
      KdfId.aes => _transformAes(data, parameters),
      _ => throw UnsupportedValueError('unknown KDF type')
    };
  }

  static List<int> _encryptArgon2(
    List<int> data,
    ParametersMap kdfParams,
    hashlib.Argon2Type argon2type,
  ) {
    final salt = kdfParams.get('S');
    if (salt is! List<int> || salt.length != 32) {
      throw FileCorruptedError('bad argon2 salt');
    }

    final parallelism = kdfParams.get('P');
    if (parallelism is! int || parallelism < 1) {
      throw FileCorruptedError('bad argon2 parallelism');
    }

    final iterations = kdfParams.get('I');
    if (iterations is! int || iterations < 1) {
      throw FileCorruptedError('bad argon2 iterations');
    }

    final memory = kdfParams.get('M');
    if (memory is! int || memory < 1 || memory % DataSize.kibi != 0) {
      throw FileCorruptedError('bad argon2 memory');
    }

    final v = kdfParams.get('V');
    final version = hashlib.Argon2Version.values.firstWhere(
      (version) => version.value == v,
      orElse: () => throw UnsupportedValueError('argon2 version'),
    );

    if (kdfParams.get('K') != null) {
      throw UnsupportedValueError('argon2 secret key');
    }

    if (kdfParams.get('A') != null) {
      throw UnsupportedValueError('argon2 assoc data');
    }

    final argon = hashlib.Argon2(
      type: argon2type,
      version: version,
      parallelism: parallelism,
      memorySizeKB: memory ~/ DataSize.kibi,
      iterations: iterations,
      salt: salt,
    );

    final digest = argon.convert(data);
    return digest.bytes;
  }

  static _transformAes(List<int> key, ParametersMap kdfParams) {
    final salt = kdfParams.get('S');
    if (salt is! List<int> || salt.length != 32) {
      throw FileCorruptedError('bad aes salt');
    }

    final rounds = kdfParams.get('R');
    if (rounds is! int || rounds < 1) {
      throw FileCorruptedError('bad aes rounds');
    }

    return KeyEncryptorAes.transform(
      data: key,
      seed: salt,
      rounds: rounds,
    );
  }
}
