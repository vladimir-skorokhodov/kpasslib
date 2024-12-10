import 'dart:convert';
import 'dart:typed_data';

import 'package:kpasslib/kpasslib.dart';
import 'package:pointycastle/export.dart';

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
        _encryptArgon2(data, parameters, Argon2Parameters.ARGON2_d),
      KdfId.argon2id =>
        _encryptArgon2(data, parameters, Argon2Parameters.ARGON2_id),
      KdfId.aes => _transformAes(data, parameters),
      _ => throw UnsupportedValueError('unknown KDF type')
    };
  }

  static List<int> _encryptArgon2(
    List<int> data,
    ParametersMap kdfParams,
    int argon2type,
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

    final version = kdfParams.get('V');
    if (version is! int ||
        (version != Argon2Parameters.ARGON2_VERSION_13 &&
            version != Argon2Parameters.ARGON2_VERSION_10)) {
      throw UnsupportedValueError('argon2 version');
    }

    final secretKey = kdfParams.get('K');
    if (secretKey != null) {
      throw UnsupportedValueError('argon2 secret key');
    }

    final assocData = kdfParams.get('A');
    if (assocData != null) {
      throw UnsupportedValueError('argon2 assoc data');
    }

    final argon = Argon2BytesGenerator()
      ..init(Argon2Parameters(
        argon2type,
        Uint8List.fromList(salt),
        desiredKeyLength: 32,
        iterations: iterations,
        lanes: parallelism,
        version: version,
        memory: memory ~/ DataSize.kibi,
      ));

    return argon.process(Uint8List.fromList(data));
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
