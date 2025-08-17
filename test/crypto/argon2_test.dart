import 'dart:ffi';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:kpasslib/kpasslib.dart';
import 'package:kpasslib/src/crypto/argon2.dart';
import 'package:kpasslib/src/crypto/dart/crypto_dart.dart';
import 'package:kpasslib/src/crypto/ffi/crypto_ffi.dart';
import 'package:test/test.dart';

import '../test_resources.dart';

void main() {
  final libPath = _nativeLibPath();
  final hasNative = File(libPath).existsSync();
  CryptoFfi? cryptoFfi;
  final cryptoDart = CryptoDart();

  setUpAll(() async {
    await TestResources.init();
    if (hasNative) {
      cryptoFfi = CryptoFfi(DynamicLibrary.open(libPath));
    }
  });

  group('Argon2 unit tests', () {
    test('argon2id produces expected hash', () {
      _testArgon2(cryptoDart);
    });

    test('native argon2id produces expected hash',
        skip: hasNative ? null : 'Native library not found', () {
      _testArgon2(cryptoFfi!);
    });

    test('argon2id is deterministic for same input', () {
      _testArgon2Repeatable(cryptoDart);
    });

    test('native argon2id is deterministic for same input',
        skip: hasNative ? null : 'Native library not found', () {
      _testArgon2Repeatable(cryptoFfi!);
    });

    test('loads kdbx4 file with argon2id kdf', () async {
      Crypto.engine = cryptoDart;
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);
      final db = await KdbxDatabase.fromBytes(
          data: TestResources.argon2id, credentials: credentials);

      expect(db.meta.generator, 'KeePass');
      expect(db.groups.isNotEmpty, isTrue);
    });

    test('native loads kdbx4 file with argon2id kdf',
        skip: hasNative ? null : 'Native library not found', () async {
      Crypto.engine = cryptoFfi!;
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);
      final db = await KdbxDatabase.fromBytes(
          data: TestResources.argon2id, credentials: credentials);

      expect(db.meta.generator, 'KeePass');
      expect(db.groups.isNotEmpty, isTrue);
    });

    test('loads kdbx4 file with argon2 kdf', () async {
      Crypto.engine = cryptoDart;
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);
      final db = await KdbxDatabase.fromBytes(
          data: TestResources.argon2, credentials: credentials);

      expect(db.meta.generator, 'KeePass');
      expect(db.groups.isNotEmpty, isTrue);
    });

    test('native loads kdbx4 file with argon2 kdf',
        skip: hasNative ? null : 'Native library not found', () async {
      Crypto.engine = cryptoFfi!;
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);
      final db = await KdbxDatabase.fromBytes(
          data: TestResources.argon2, credentials: credentials);

      expect(db.meta.generator, 'KeePass');
      expect(db.groups.isNotEmpty, isTrue);
    });
  });
}

void _testArgon2(CryptoEngine engine) {
  final argon2 = engine.createArgon2(
    type: Argon2Type.argon2id,
    version: Argon2Version.v13,
    parallelism: 2,
    memorySizeKB: 16,
    iterations: 1,
    salt: List<int>.generate(32, (i) => i == 0 ? 42 : 0),
  );

  final password = hex.decode(
      '5d18f8a5ae0e7ea86f0ad817f0c0d40656ef1da6367d8a88508b3c13cec0d7af');
  final result = argon2.convert(password);

  expect(hex.encode(result),
      '2aecd80625a328efb2029319b0b205ab3b7a9b60fbde1b46194e4f77933297a3');
}

void _testArgon2Repeatable(CryptoEngine engine) {
  final argon2 = engine.createArgon2(
    type: Argon2Type.argon2id,
    version: Argon2Version.v13,
    parallelism: 2,
    memorySizeKB: 16,
    iterations: 1,
    salt: List<int>.generate(32, (i) => i == 0 ? 42 : 0),
  );

  final password = hex.decode(
      '5d18f8a5ae0e7ea86f0ad817f0c0d40656ef1da6367d8a88508b3c13cec0d7af');
  final first = argon2.convert(password);
  final second = argon2.convert(password);

  expect(second, first);
}

String _nativeLibPath() {
  final root = Directory.current.path;
  final name = switch (Platform.operatingSystem) {
    'macos' || 'ios' => 'libkreepto.dylib',
    'linux' || 'android' => 'libkreepto.so',
    'windows' => 'kreepto.dll',
    _ => throw UnsupportedError(
        'Unsupported platform: ${Platform.operatingSystem}'),
  };
  return '$root/native/kreepto-rust/target/release/$name';
}
