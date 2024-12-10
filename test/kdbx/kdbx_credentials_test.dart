import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:kpasslib/kpasslib.dart';
import 'package:test/test.dart';

void main() {
  group('Credentials unit tests', () {
    test('calculates hash for credentials without password or key-file', () {
      final credentials = KdbxCredentials();
      expect(hex.encode(credentials.hash),
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
    });

    test('calculates hash for credentials with empty password only', () {
      final credentials =
          KdbxCredentials(password: ProtectedData.fromString(''));
      expect(hex.encode(credentials.hash),
          '5df6e0e2761359d30a8275058e299fcc0381534545f55cf43e41983f5d4c9456');
    });

    test('calculates hash for credentials with test password only', () {
      final credentials =
          KdbxCredentials(password: ProtectedData.fromString('test'));
      expect(hex.encode(credentials.hash),
          '954d5a49fd70d9b8bcdb35d252267829957f7ef7fa6c74f88419bdc5e82209f4');
    });

    test(
        'calculates hash for credentials without password and with a plain text key-file',
        () {
      final credentials = KdbxCredentials(keyData: List<int>.filled(32, 1));
      expect(hex.encode(credentials.hash),
          '72cd6e8422c407fb6d098690f1130b7ded7ec2f7f5e1d30bd9d521f015363793');
    });

    test(
        'calculates hash for credentials with test password and with a key-file',
        () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('test'),
          keyData: List<int>.filled(32, 1));
      expect(hex.encode(credentials.hash),
          'e37a11dc890fae6114bbc310a22a5b9bef0d253d4843679b4d76501bb849600e');
    });

    test('calculates hash with challenge-response', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('test'),
          keyData: List<int>.filled(32, 1),
          challengeResponse: (challenge) => challenge);
      final hash = credentials.getHash(challenge: List<int>.filled(32, 2));
      expect(hex.encode(hash),
          '8cdc398b5e3906296d8b69f9a88162fa65b46bca0f9ac4024b083411d4a76324');
    });

    test('calculates hash for credentials with an unformatted key-file', () {
      final credentials = KdbxCredentials(keyData: utf8.encode('boo'));
      expect(hex.encode(credentials.hash),
          '3ab83b7980ccad2dca61dd5f60d306c71d80f2d9856a72e2743d17cbb1c3cbf6');
    });

    test('calculates hash for credentials with a hex key-file', () {
      final credentials = KdbxCredentials(
          keyData: utf8.encode(
              'DEADbeef0a0f0212812374283418418237418734873829748917389472314243'));
      expect(hex.encode(credentials.hash),
          'cf18a98ff868a7978dddc09861f792e6fe6d13503f4364ae2e1abeef2ba5bfc9');
    });

    test('throws an error for an xml key-file without meta', () {
      expect(
          () => KdbxCredentials(keyData: utf8.encode('<KeyFile/>')),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('xml key-file without meta element'))));
    });

    test('throws an error for an xml key-file without version', () {
      expect(
          () => KdbxCredentials(
              keyData: utf8.encode('<KeyFile><Meta></Meta></KeyFile>')),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('xml key-file without version element'))));
    });

    test('throws an error for an xml key-file with bad version', () {
      expect(
          () => KdbxCredentials(
              keyData: utf8.encode(
                  '<KeyFile><Meta><Version>10.0</Version></Meta><Key><Data>00</Data></Key></KeyFile>')),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('xml key-file version'))));
    });

    test('throws an error for an xml key-file without key element', () {
      expect(
          () => KdbxCredentials(
              keyData: utf8.encode(
                  '<KeyFile><Meta><Version>1.0</Version></Meta></KeyFile>')),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('xml key-file without key element'))));
    });

    test('throws an error for an xml key-file without data', () {
      expect(
          () => KdbxCredentials(
              keyData: utf8.encode(
                  '<KeyFile><Meta><Version>1.0</Version></Meta><Key></Key></KeyFile>')),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('xml key-file without data element'))));
    });

    test('calculates hash for a v1 xml key-file', () {
      final credentials = KdbxCredentials(
          keyData: utf8.encode(
              '<KeyFile><Meta><Version>1.0</Version></Meta><Key><Data>AtY2GR2pVt6aWz2ugfxfSQWjRId9l0JWe/LEMJWVJ1k=</Data></Key></KeyFile>'));
      expect(hex.encode(credentials.hash),
          '829bd09b8d05fafaa0e80b7307a978c496931815feb0a5cf82ce872ee36fa355');
    });

    test('calculates hash for a v2 xml key-file', () {
      final credentials = KdbxCredentials(
          keyData: utf8.encode(
              '<KeyFile><Meta><Version>2.0</Version></Meta><Key><Data Hash="FE2949B8">A7007945 D07D54BA 28DF6434 1B4500FC 9750DFB1 D36ADA2D 9C32DC19 4C7AB01B</Data></Key></KeyFile>'));
      expect(hex.encode(credentials.hash),
          'fe2949b83209abdbd99f049b6a0231282b5854214b0b58f5135148f905ad5a95');
    });

    test('throws an error for a v2 xml key-file with bad hash', () {
      expect(
          () => KdbxCredentials(
              keyData: utf8.encode(
                  '<KeyFile><Meta><Version>2.0</Version></Meta><Key><Data Hash="AABBCCDD">A7007945 D07D54BA 28DF6434 1B4500FC 9750DFB1 D36ADA2D 9C32DC19 4C7AB01B</Data></Key></KeyFile>')),
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('xml key-file data hash mismatch'))));
    });
  });
}
