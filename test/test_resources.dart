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
    const assets = 'assets/test';
    demoKey = File('$assets/demo.key').readAsBytesSync();
    demoKdbx = File('$assets/demo.kdbx').readAsBytesSync();
    demoXml = File('$assets/demo.xml').readAsBytesSync();
    demoIcon = File('$assets/demoIcon.png').readAsBytesSync();
    cyrillicKdbx = File('$assets/cyrillic.kdbx').readAsBytesSync();
    binKeyKey = File('$assets/binKey.key').readAsBytesSync();
    binKeyKdbx = File('$assets/binKey.kdbx').readAsBytesSync();
    emptyPass = File('$assets/emptyPass.kdbx').readAsBytesSync();
    emptyPassWithKeyFileKey =
        File('$assets/emptyPassWithKeyFile.key').readAsBytesSync();
    emptyPassWithKeyFile =
        File('$assets/emptyPassWithKeyFile.kdbx').readAsBytesSync();
    noPassWithKeyFileKey =
        File('$assets/noPassWithKeyFile.key').readAsBytesSync();
    noPassWithKeyFile =
        File('$assets/noPassWithKeyFile.kdbx').readAsBytesSync();
    key32Key = File('$assets/key32.key').readAsBytesSync();
    key32 = File('$assets/key32.kdbx').readAsBytesSync();
    key64Key = File('$assets/key64.key').readAsBytesSync();
    key64 = File('$assets/key64.kdbx').readAsBytesSync();
    keyWithBomKey = File('$assets/keyWithBom.key').readAsBytesSync();
    keyWithBom = File('$assets/keyWithBom.kdbx').readAsBytesSync();
    keyV2Key = File('$assets/keyV2.keyx').readAsBytesSync();
    keyV2 = File('$assets/keyV2.kdbx').readAsBytesSync();
    argon2 = File('$assets/argon2.kdbx').readAsBytesSync();
    argon2id = File('$assets/argon2id.kdbx').readAsBytesSync();
    aesChaCha = File('$assets/aesChaCha.kdbx').readAsBytesSync();
    aesKdfKdbx4 = File('$assets/aesKdfKdbx4.kdbx').readAsBytesSync();
    argon2ChaCha = File('$assets/argon2ChaCha.kdbx').readAsBytesSync();
    yubikey3 = File('$assets/yubikey3.kdbx').readAsBytesSync();
    yubikey4 = File('$assets/yubikey4.kdbx').readAsBytesSync();
    emptyUuidXml = File('$assets/emptyUuid.xml').readAsBytesSync();
    kdbx41 = File('$assets/kdbx4.1.kdbx').readAsBytesSync();
    mergeKdbx = File('$assets/merge.kdbx').readAsBytesSync();
  }
}
