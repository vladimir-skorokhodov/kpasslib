import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:kpasslib/kpasslib.dart';
import 'package:kpasslib/src/crypto/key_encryptor_kdf.dart';
import 'package:kpasslib/src/utils/parameters_map.dart';
import 'package:test/test.dart';

void main() {
  group('KeyEncryptorKdf unit tests', () {
    final data = hex.decode(
        '5d18f8a5ae0e7ea86f0ad817f0c0d40656ef1da6367d8a88508b3c13cec0d7af');

    test('calls argon2 function', () {
      final params = ParametersMap()
        ..addAll([
          ('\$UUID', ParameterType.bytes, base64.decode(KdfId.argon2d)),
          (
            'S',
            ParameterType.bytes,
            List<int>.generate(32, (i) => i == 0 ? 42 : 0)
          ),
          ('P', ParameterType.uInt32, 2),
          ('I', ParameterType.uInt64, 1),
          ('M', ParameterType.uInt64, 16 * DataSize.kibi),
          ('V', ParameterType.uInt32, 0x13)
        ]);

      final res = KeyEncryptorKdf.encrypt(data: data, parameters: params);
      expect(hex.encode(res),
          '37597075e9b6d90c492183bb56214b4d9eb04c4d0971fd11f929d1e4155dff32');
    });

    test('throws error for no uuid', () {
      final params = ParametersMap();

      expect(
          () => KeyEncryptorKdf.encrypt(data: data, parameters: params),
          throwsA(predicate((e) =>
              e is FileCorruptedError && e.message.contains('no kdf uuid'))));
    });

    test('throws error for invalid uuid', () {
      final params = ParametersMap()
        ..addAll([('\$UUID', ParameterType.bytes, List.filled(32, 0))]);

      expect(
        () => KeyEncryptorKdf.encrypt(data: data, parameters: params),
        throwsA(
          predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('unknown KDF type')),
        ),
      );
    });

    test('throws error for bad salt', () {
      final params = ParametersMap()
        ..addAll([
          ('\$UUID', ParameterType.bytes, base64.decode(KdfId.argon2d)),
          ('S', ParameterType.bytes, List.filled(10, 0))
        ]);

      expect(
          () => KeyEncryptorKdf.encrypt(data: data, parameters: params),
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('bad argon2 salt'))));
    });

    test('throws error for bad parallelism', () {
      final params = ParametersMap()
        ..addAll([
          ('\$UUID', ParameterType.bytes, base64.decode(KdfId.argon2d)),
          (
            'S',
            ParameterType.bytes,
            List<int>.generate(32, (i) => i == 0 ? 42 : 0)
          ),
          ('P', ParameterType.uInt32, -1)
        ]);

      expect(
          () => KeyEncryptorKdf.encrypt(data: data, parameters: params),
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('bad argon2 parallelism'))));
    });

    test('throws error for bad parallelism type', () {
      final params = ParametersMap()
        ..addAll([
          ('\$UUID', ParameterType.bytes, base64.decode(KdfId.argon2d)),
          (
            'S',
            ParameterType.bytes,
            List<int>.generate(32, (i) => i == 0 ? 42 : 0)
          ),
          ('P', ParameterType.string, 'xxx')
        ]);

      expect(
          () => KeyEncryptorKdf.encrypt(data: data, parameters: params),
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('bad argon2 parallelism'))));
    });

    test('throws error for bad iterations', () {
      final params = ParametersMap()
        ..addAll([
          ('\$UUID', ParameterType.bytes, base64.decode(KdfId.argon2d)),
          (
            'S',
            ParameterType.bytes,
            List<int>.generate(32, (i) => i == 0 ? 42 : 0)
          ),
          ('P', ParameterType.uInt32, 1),
          ('I', ParameterType.int32, -1)
        ]);

      expect(
          () => KeyEncryptorKdf.encrypt(data: data, parameters: params),
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('bad argon2 iterations'))));
    });

    test('throws error for bad memory', () {
      final params = ParametersMap()
        ..addAll([
          ('\$UUID', ParameterType.bytes, base64.decode(KdfId.argon2d)),
          (
            'S',
            ParameterType.bytes,
            List<int>.generate(32, (i) => i == 0 ? 42 : 0)
          ),
          ('P', ParameterType.uInt32, 2),
          ('I', ParameterType.uInt64, 1),
          ('M', ParameterType.uInt64, 123)
        ]);

      expect(
          () => KeyEncryptorKdf.encrypt(data: data, parameters: params),
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('bad argon2 memory'))));
    });

    test('throws error for bad version', () {
      final params = ParametersMap()
        ..addAll([
          ('\$UUID', ParameterType.bytes, base64.decode(KdfId.argon2d)),
          (
            'S',
            ParameterType.bytes,
            List<int>.generate(32, (i) => i == 0 ? 42 : 0)
          ),
          ('P', ParameterType.uInt32, 2),
          ('I', ParameterType.uInt64, 1),
          ('M', ParameterType.uInt64, 4 * DataSize.kibi),
          ('V', ParameterType.uInt32, 5)
        ]);

      expect(
          () => KeyEncryptorKdf.encrypt(data: data, parameters: params),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('argon2 version'))));
    });

    test('throws error for secret key', () {
      final params = ParametersMap()
        ..addAll([
          ('\$UUID', ParameterType.bytes, base64.decode(KdfId.argon2d)),
          (
            'S',
            ParameterType.bytes,
            List<int>.generate(32, (i) => i == 0 ? 42 : 0)
          ),
          ('P', ParameterType.uInt32, 2),
          ('I', ParameterType.uInt64, 1),
          ('M', ParameterType.uInt64, 4 * DataSize.kibi),
          ('V', ParameterType.uInt32, 0x13),
          ('K', ParameterType.bytes, List.filled(32, 0))
        ]);

      expect(
          () => KeyEncryptorKdf.encrypt(data: data, parameters: params),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('argon2 secret key'))));
    });

    test('throws error for assoc data', () {
      final params = ParametersMap()
        ..addAll([
          ('\$UUID', ParameterType.bytes, base64.decode(KdfId.argon2d)),
          (
            'S',
            ParameterType.bytes,
            List<int>.generate(32, (i) => i == 0 ? 42 : 0)
          ),
          ('P', ParameterType.uInt32, 2),
          ('I', ParameterType.uInt64, 1),
          ('M', ParameterType.uInt64, 4 * DataSize.kibi),
          ('V', ParameterType.uInt32, 0x13),
          ('A', ParameterType.bytes, List.filled(32, 0))
        ]);

      expect(
          () => KeyEncryptorKdf.encrypt(data: data, parameters: params),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('argon2 assoc data'))));
    });

    test('calls aes function', () {
      final params = ParametersMap()
        ..addAll([
          ('\$UUID', ParameterType.bytes, base64.decode(KdfId.aes)),
          (
            'S',
            ParameterType.bytes,
            hex.decode(
                '5d18f8a5ae0e7ea86f0ad817f0c0d40656ef1da6367d8a88508b3c13cec0d7af')
          ),
          ('R', ParameterType.uInt64, 2)
        ]);

      final res = KeyEncryptorKdf.encrypt(
          data: hex.decode(
              'ee66af917de0b0336e659fe6bd40a337d04e3c2b3635210fa16f28fb24d563ac'),
          parameters: params);
      expect(hex.encode(res),
          'af0be2c639224ad37bd2bc7967d6c3303a8a6d4b7813718918a66bde96dc3132');
    });

    test('throws error for bad aes salt', () {
      final params = ParametersMap()
        ..addAll([
          ('\$UUID', ParameterType.bytes, base64.decode(KdfId.aes)),
          ('S', ParameterType.bytes, List.filled(10, 0)),
          ('R', ParameterType.uInt64, 2)
        ]);

      expect(
          () => KeyEncryptorKdf.encrypt(data: data, parameters: params),
          throwsA(predicate((e) =>
              e is FileCorruptedError && e.message.contains('bad aes salt'))));
    });

    test('throws error for bad aes rounds', () {
      final params = ParametersMap()
        ..addAll([
          ('\$UUID', ParameterType.bytes, base64.decode(KdfId.aes)),
          ('S', ParameterType.bytes, List.filled(32, 0)),
          ('R', ParameterType.int64, -1)
        ]);

      expect(
          () => KeyEncryptorKdf.encrypt(data: data, parameters: params),
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('bad aes rounds'))));
    });
  });
}
