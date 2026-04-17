import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:kpasslib/kpasslib.dart';
import 'package:kpasslib/src/crypto/crypto_utils.dart';
import 'package:kpasslib/src/crypto/dart/crypto_dart.dart';
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

  group('AES unit tests', () {
    final data =
        Uint8List.fromList(hex.decode('5d18f8a5ae0e7ea86f0ad817f0c0d406'));
    final key = Uint8List.fromList(hex.decode(
        'ee66af917de0b0336e659fe6bd40a337d04e3c2b3635210fa16f28fb24d563ac'));

    test('CBC encrypt then decrypt roundtrip', () {
      _testRoundtrup(cryptoDart);
    });

    test('native CBC encrypt then decrypt roundtrip',
        skip: hasNative ? null : 'Native library not found', () {
      _testRoundtrup(cryptoFfi!);
    });

    test('transformBlock 1 round', () async {
      final result = Uint8List.fromList(data);
      cryptoDart.createAes256(key: key).transformBlock(data: result, rounds: 1);
      expect(hex.encode(result), '46e891c182a31d005a8990ac5d61bb21');
    });

    test('native transformBlock 1 round',
        skip: hasNative ? null : 'Native library not found', () async {
      final result = Uint8List.fromList(data);
      cryptoFfi!.createAes256(key: key).transformBlock(data: result, rounds: 1);
      expect(hex.encode(result), '46e891c182a31d005a8990ac5d61bb21');
    });

    test('transformBlock 2 rounds', () async {
      final result = Uint8List.fromList(data);
      cryptoDart.createAes256(key: key).transformBlock(data: result, rounds: 2);
      expect(hex.encode(result), '1818f732cb1a933911ec90baed252d38');
    });

    test('native transformBlock 2 rounds',
        skip: hasNative ? null : 'Native library not found', () async {
      final result = Uint8List.fromList(data);
      cryptoFfi!.createAes256(key: key).transformBlock(data: result, rounds: 2);
      expect(hex.encode(result), '1818f732cb1a933911ec90baed252d38');
    });

    test('transformBlock 10021 rounds', () async {
      final result = Uint8List.fromList(data);
      cryptoDart
          .createAes256(key: key)
          .transformBlock(data: result, rounds: 10021);
      expect(hex.encode(result), '64d62f7ec4a363ff0fbb4520163b478e');
    });

    test('native transformBlock 10021 rounds',
        skip: hasNative ? null : 'Native library not found', () async {
      final result = Uint8List.fromList(data);
      cryptoFfi!
          .createAes256(key: key)
          .transformBlock(data: result, rounds: 10021);
      expect(hex.encode(result), '64d62f7ec4a363ff0fbb4520163b478e');
    });

    test('loads AES-encrypted KDBX', () async {
      Crypto.engine = cryptoDart;
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);
      final db = await KdbxDatabase.fromBytes(
        data: Uint8List.fromList(TestResources.demoKdbx),
        credentials: credentials,
      );
      expect(db.groups.isNotEmpty, isTrue);
    });

    test('native loads AES-encrypted KDBX',
        skip: hasNative ? null : 'Native library not found', () async {
      Crypto.engine = cryptoFfi!;
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);
      final db = await KdbxDatabase.fromBytes(
        data: Uint8List.fromList(TestResources.demoKdbx),
        credentials: credentials,
      );
      expect(db.groups.isNotEmpty, isTrue);
    });
  });
}

void _testRoundtrup(CryptoEngine engine) {
  final data = CryptoUtils.randomBytes(16);
  final key = CryptoUtils.randomBytes(32);
  final iv = CryptoUtils.randomBytes(16);
  final aes = engine.createAes256(key: key);
  final encoded = aes.encryptCbc(data: data, iv: iv);
  expect(ListEquality().equals(encoded, data), false);

  final decoded = aes.decryptCbc(data: encoded, iv: iv);
  expect(decoded, data);
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
