import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:kpasslib/src/crypto/dart/crypto_dart.dart';
import 'package:kpasslib/src/crypto/ffi/crypto_ffi.dart';
import 'package:test/test.dart';

void main() {
  final libPath = _nativeLibPath();
  final hasNative = File(libPath).existsSync();
  CryptoFfi? cryptoFfi;
  CryptoDart cryptoDart = CryptoDart();

  setUpAll(() async {
    if (hasNative) {
      cryptoFfi = CryptoFfi(DynamicLibrary.open(libPath));
    }
  });

  group('Salsa20 unit tests', () {
    test('RFC 4137 test vector (counter=0)', () {
      _testZeroList(cryptoDart);
    });

    test('native RFC 4137 test vector (counter=0)',
        skip: hasNative ? null : 'Native library not found', () {
      _testZeroList(cryptoFfi!);
    });

    test('encrypt then decrypt roundtrip', () {
      _testRandomRoundtrip(cryptoDart);
    });

    test('native encrypt then decrypt roundtrip',
        skip: hasNative ? null : 'Native library not found', () {
      _testRandomRoundtrip(cryptoFfi!);
    });

    test('handles partial last block', () {
      _testPartialLastBlock(cryptoDart);
    });

    test('native handles partial last block',
        skip: hasNative ? null : 'Native library not found', () {
      _testPartialLastBlock(cryptoFfi!);
    });
  });
}

_testZeroList(dynamic engine) {
  final key = Uint8List(32);
  final nonce = Uint8List(8);
  final plaintext = Uint8List(64);

  const expectedHex = '9a97f65b9b4c721b960a672145fca8d4'
      'e32e67f9111ea979ce9c4826806aeee6'
      '3de9c0da2bd7f91ebcb2639bf989c625'
      '1b29bf38d39a9bdce7c55f4b2ac12a39';

  final cipher = engine.createSalsa20(key: key).transform(
        data: plaintext,
        nonce: nonce,
      );
  expect(hex.encode(cipher), expectedHex);
}

_testRandomRoundtrip(dynamic engine) {
  final data = Uint8List.fromList(List.generate(500, (i) => i & 0xFF));
  final key = Uint8List.fromList(List.generate(32, (i) => i & 0xFF));
  final nonce = Uint8List.fromList(List.generate(8, (i) => i & 0xFF));

  final salsa = engine.createSalsa20(key: key);
  final encrypted = salsa.transform(data: data, nonce: nonce);
  expect(ListEquality().equals(encrypted, data), false);

  final decrypted = salsa.transform(data: encrypted, nonce: nonce);
  expect(decrypted, data);
}

_testPartialLastBlock(dynamic engine) {
  final data = Uint8List(100);
  final key = Uint8List(32);
  final nonce = Uint8List(8);

  final salsa = engine.createSalsa20(key: key);
  final encrypted = salsa.transform(data: data, nonce: nonce);
  expect(encrypted.length, 100);

  final decrypted = salsa.transform(data: encrypted, nonce: nonce);
  expect(decrypted, data);
}

String _nativeLibPath() {
  final root = Directory.current.path;
  final name = switch (Platform.operatingSystem) {
    'macos' => 'libkreepto.dylib',
    'linux' => 'libkreepto.so',
    'windows' => 'kreepto.dll',
    _ => throw UnsupportedError(
        'Unsupported platform: ${Platform.operatingSystem}'),
  };
  return '$root/native/kreepto-rust/target/release/$name';
}
