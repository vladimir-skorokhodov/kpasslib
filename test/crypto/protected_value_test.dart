import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:kpasslib/kpasslib.dart';
import 'package:test/test.dart';

void main() {
  group('ProtectedData unit tests', () {
    const stringValue = 'string test value';
    final binaryValue = utf8.encode(stringValue);
    final salt = List<int>.generate(binaryValue.length, (i) => i);
    final encBinaryValue =
        List<int>.generate(binaryValue.length, (i) => binaryValue[i] ^ salt[i]);

    test('decrypts salted value in string', () {
      final value =
          ProtectedData.fromProtectedBytes(bytes: encBinaryValue, salt: salt);
      expect(value.text, stringValue);
    });

    test('returns string in binary', () {
      final value =
          ProtectedData.fromProtectedBytes(bytes: encBinaryValue, salt: salt);
      expect(value.bytes, binaryValue);
    });

    test('calculates hash', () {
      final value =
          ProtectedData.fromProtectedBytes(bytes: encBinaryValue, salt: salt);
      final hash = hex.encode(value.hash);
      expect(hash,
          'd46fd3473d7753cd7430f4137c740593441a6ece1440486490e00807349d0dd4');
    });

    test('creates value from string', () {
      final pv = ProtectedData.fromString(stringValue);
      expect(pv.bytes, binaryValue);
      expect(pv.text, stringValue);
    });

    test('creates value from binary', () {
      final pv = ProtectedData.fromBytes(binaryValue);
      expect(pv.bytes, binaryValue);
      expect(pv.text, stringValue);
    });
  });
}
