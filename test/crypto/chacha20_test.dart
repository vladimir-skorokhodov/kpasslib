import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:kpasslib/kpasslib.dart';
import 'package:kpasslib/src/crypto/dart/crypto_dart.dart';
import 'package:kpasslib/src/crypto/ffi/crypto_ffi.dart';
import 'package:test/test.dart';

import '../test_resources.dart';

void main() {
  final libPath = _nativeLibPath();
  final hasNative = File(libPath).existsSync();
  CryptoFfi? cryptoFfi;
  CryptoDart cryptoDart = CryptoDart();

  setUpAll(() async {
    if (hasNative) {
      cryptoFfi = CryptoFfi(DynamicLibrary.open(libPath));
    }
    await TestResources.init();
  });

  group('ChaCha20 unit tests', () {
    test('RFC 7539 A.2 test vector 1 (counter=0)', () {
      _testZeroList(cryptoDart);
    });

    test('native RFC 7539 A.2 test vector 1 (counter=0)',
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

    test('loads ChaCha20-encrypted KDBX', () async {
      await _testKdbxLoading(cryptoDart);
    });

    test('native loads ChaCha20-encrypted KDBX',
        skip: hasNative ? null : 'Native library not found', () async {
      await _testKdbxLoading(cryptoFfi!);
    });
  });
}

_testZeroList(CryptoEngine engine) {
  final key = Uint8List(32);
  final nonce = Uint8List(12);
  final plaintext = Uint8List(64);

  const expectedHex = '76b8e0ada0f13d90405d6ae55386bd28'
      'bdd219b8a08ded1aa836efcc8b770dc7'
      'da41597c5157488d7724e03fb8d84a37'
      '6a43b8f41518a11cc387b669b2ee6586';

  final cipher =
      engine.createChaCha20(key: key).transform(data: plaintext, nonce: nonce);
  expect(hex.encode(cipher), expectedHex);
}

_testRandomRoundtrip(CryptoEngine engine) {
  final data = CryptoUtils.randomBytes(500);
  final key = CryptoUtils.randomBytes(32);
  final nonce = CryptoUtils.randomBytes(12);

  final chacha = engine.createChaCha20(key: key);
  final encrypted = chacha.transform(data: data, nonce: nonce);
  expect(ListEquality().equals(encrypted, data), false);

  final decrypted = chacha.transform(data: encrypted, nonce: nonce);
  expect(decrypted, data);
}

_testPartialLastBlock(CryptoEngine engine) {
  final data = Uint8List(100);
  final key = Uint8List(32);
  final nonce = Uint8List(12);

  final chacha = engine.createChaCha20(key: key);
  final encrypted = chacha.transform(data: data, nonce: nonce);
  expect(encrypted.length, 100);

  final decrypted = chacha.transform(data: encrypted, nonce: nonce);
  expect(decrypted, data);
}

_testKdbxLoading(CryptoEngine engine) async {
  Crypto.engine = engine;
  final credentials = KdbxCredentials(
      password: ProtectedData.fromString('demo'),
      keyData: TestResources.demoKey);
  final db = await KdbxDatabase.fromBytes(
    data: Uint8List.fromList(TestResources.argon2ChaCha),
    credentials: credentials,
  );
  expect(db.groups.isNotEmpty, isTrue);
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
