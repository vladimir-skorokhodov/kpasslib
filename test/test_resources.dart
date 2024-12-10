import 'dart:io';

class TestResources {
  static var demoKey = <int>[];
  static var demoKdbx = <int>[];
  static var demoXml = <int>[];
  static var demoIcon = <int>[];
  static var cyrillicKdbx = <int>[];
  static var binKeyKey = <int>[];
  static var binKeyKdbx = <int>[];
  static var emptyPass = <int>[];
  static var emptyPassWithKeyFileKey = <int>[];
  static var emptyPassWithKeyFile = <int>[];
  static var noPassWithKeyFileKey = <int>[];
  static var noPassWithKeyFile = <int>[];
  static var key32Key = <int>[];
  static var key32 = <int>[];
  static var key64Key = <int>[];
  static var key64 = <int>[];
  static var keyWithBomKey = <int>[];
  static var keyWithBom = <int>[];
  static var keyV2Key = <int>[];
  static var keyV2 = <int>[];
  static var argon2 = <int>[];
  static var argon2id = <int>[];
  static var aesChaCha = <int>[];
  static var aesKdfKdbx4 = <int>[];
  static var argon2ChaCha = <int>[];
  static var yubikey3 = <int>[];
  static var yubikey4 = <int>[];
  static var emptyUuidXml = <int>[];
  static var kdbx41 = <int>[];
  static var mergeKdbx = <int>[];

  static init() async {
    demoKey = File('./assets/test/demo.key').readAsBytesSync();
    demoKdbx = File('./assets/test/demo.kdbx').readAsBytesSync();
    demoXml = File('./assets/test/demo.xml').readAsBytesSync();
    demoIcon = File('./assets/test/demoIcon.png').readAsBytesSync();
    cyrillicKdbx = File('./assets/test/cyrillic.kdbx').readAsBytesSync();
    binKeyKey = File('./assets/test/binKey.key').readAsBytesSync();
    binKeyKdbx = File('./assets/test/binKey.kdbx').readAsBytesSync();
    emptyPass = File('./assets/test/emptyPass.kdbx').readAsBytesSync();
    emptyPassWithKeyFileKey =
        File('./assets/test/emptyPassWithKeyFile.key').readAsBytesSync();
    emptyPassWithKeyFile =
        File('./assets/test/emptyPassWithKeyFile.kdbx').readAsBytesSync();
    noPassWithKeyFileKey =
        File('./assets/test/noPassWithKeyFile.key').readAsBytesSync();
    noPassWithKeyFile =
        File('./assets/test/noPassWithKeyFile.kdbx').readAsBytesSync();
    key32Key = File('./assets/test/key32.key').readAsBytesSync();
    key32 = File('./assets/test/key32.kdbx').readAsBytesSync();
    key64Key = File('./assets/test/key64.key').readAsBytesSync();
    key64 = File('./assets/test/key64.kdbx').readAsBytesSync();
    keyWithBomKey = File('./assets/test/keyWithBom.key').readAsBytesSync();
    keyWithBom = File('./assets/test/keyWithBom.kdbx').readAsBytesSync();
    keyV2Key = File('./assets/test/keyV2.keyx').readAsBytesSync();
    keyV2 = File('./assets/test/keyV2.kdbx').readAsBytesSync();
    argon2 = File('./assets/test/argon2.kdbx').readAsBytesSync();
    argon2id = File('./assets/test/argon2id.kdbx').readAsBytesSync();
    aesChaCha = File('./assets/test/aesChaCha.kdbx').readAsBytesSync();
    aesKdfKdbx4 = File('./assets/test/aesKdfKdbx4.kdbx').readAsBytesSync();
    argon2ChaCha = File('./assets/test/argon2ChaCha.kdbx').readAsBytesSync();
    yubikey3 = File('./assets/test/yubikey3.kdbx').readAsBytesSync();
    yubikey4 = File('./assets/test/yubikey4.kdbx').readAsBytesSync();
    emptyUuidXml = File('./assets/test/emptyUuid.xml').readAsBytesSync();
    kdbx41 = File('./assets/test/kdbx4.1.kdbx').readAsBytesSync();
    mergeKdbx = File('./assets/test/merge.kdbx').readAsBytesSync();
  }
}
