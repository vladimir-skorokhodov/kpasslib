import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:kpasslib/kpasslib.dart';
import 'package:test/test.dart';

import '../test_resources.dart';
import 'test_database.dart';
import 'test_entry.dart';
import 'test_group.dart';
import 'test_times.dart';

abstract class DT {
  static final created = DateTime.utc(2015, 8, 16, 14, 45, 23);
  static final sampleGroupCreated = DateTime.utc(2015, 8, 16, 14, 44, 42);
  static final sampleGroupExpiry = DateTime.utc(2015, 8, 16, 14, 43, 4);
  static final generalGroupCreated = DateTime.utc(2015, 8, 16, 14, 45, 23);
  static final upd1 = DateTime.utc(2015, 8, 16, 14, 44, 42);
  static final entry11Created = DateTime.utc(2015, 8, 16, 14, 45, 54);
}

abstract class ID {
  static final trash = KdbxUuid.fromString('fZ7q9U4TBU+5VomeW3BZOQ==');
  static final sampleGroup = KdbxUuid.fromString('LWIve8M1xUuvrORCdYeRgA==');
  static final entry1 = KdbxUuid.fromString('HzYFsnGCkEKyrPtOa6bNMA==');
  static final entry11 = KdbxUuid.fromString('vqcoCvE9/k6PSgutKI6snw==');
}

abstract class Bin {
  static final bin1 = hex.decode('736f6d65206174746163686d656e74');
}

TestDatabase _getTestDb() {
  final mp = KdbxMemoryProtection();
  mp.password = true;
  mp.title = mp.userName = mp.url = mp.notes = false;
  final binaries = KdbxBinaries()
    ..add(PlainBinary(data: Bin.bin1, compressed: false));

  final sampleFields = {
    'Notes': 'some notes',
    'Title': 'my entry',
    'URL': 'http://me.me',
    'UserName': 'me',
    'my field': 'my val',
    'Password': 'mypass',
    'my field protected': 'protected val'
  };

  return TestDatabase(
    meta: TestMeta(
      name: 'demo',
      nameChanged: DT.created,
      description: 'demo db',
      descriptionChanged: DT.created,
      defaultUser: 'me',
      defaultUserChanged: DT.created,
      maintenanceHistoryDays: 365,
      color: '#FF0000',
      keyChanged: DateTime.utc(2015, 08, 16, 14, 53, 28),
      keyChangeRec: -1,
      keyChangeForce: -1,
      recycleBinEnabled: true,
      recycleBinUuid: ID.trash,
      recycleBinChanged: DT.upd1,
      entryTemplatesGroup: KdbxUuid.zero,
      entryTemplatesGroupChanged: DT.upd1,
      historyMaxItems: 10,
      historyMaxSize: 6291456,
      customIcons: {
        KdbxUuid.fromString('rr3vZ1ozek+R4pAcLeqw5w=='): KdbxCustomIcon(
          data: TestResources.demoIcon,
        ),
      },
      lastSelectedGroup: ID.sampleGroup,
      lastTopVisibleGroup: ID.sampleGroup,
      memoryProtection: mp,
      customData: KdbxCustomData(),
    ),
    binaries: binaries,
    deletedObjects: {
      KdbxUuid.fromString('LtoeZ26BBkqtr93N9tqO4g=='):
          DateTime.utc(2015, 8, 16, 14, 50, 13),
    },
    root: TestGroup(
      uuid: ID.sampleGroup,
      name: 'sample',
      notes: '',
      icon: 49,
      times: TestTimes(
        creation: DT.sampleGroupCreated,
        modification: DT.sampleGroupCreated,
        access: DateTime.utc(2015, 8, 16, 14, 50, 15),
        expiry: DT.sampleGroupExpiry,
        locationChange: DT.sampleGroupCreated,
        expires: false,
        usageCount: 28,
      ),
      isExpanded: true,
      lastTopVisibleEntry: ID.entry1,
      groups: [
        TestGroup(
          uuid: KdbxUuid.fromString('GaN4R2PK1U63ckOVDzTY6w=='),
          name: 'General',
          notes: '',
          icon: 48,
          times: TestTimes(
            creation: DT.generalGroupCreated,
            modification: DT.generalGroupCreated,
            access: DateTime.utc(2015, 8, 16, 14, 45, 51),
            expiry: DT.sampleGroupExpiry,
            locationChange: DT.generalGroupCreated,
            expires: false,
            usageCount: 3,
          ),
          isExpanded: true,
          lastTopVisibleEntry: ID.entry11,
          entries: [
            TestEntry(
              uuid: ID.entry11,
              icon: 2,
              history: [
                TestEntry(
                  uuid: ID.entry11,
                  fields: Map.from(sampleFields)
                    ..addAll({
                      'Title': 'my-entry',
                      'Password': 'pass',
                    }),
                ),
              ],
              fgColor: '#FF0000',
              bgColor: '#00FF00',
              overrideUrl: 'cmd://{GOOGLECHROME} "{URL}"',
              tags: ['my', 'tag'],
              times: TestTimes(
                creation: DT.entry11Created,
                modification: DateTime.utc(2015, 8, 16, 14, 49, 12),
                access: DateTime.utc(2015, 8, 16, 14, 49, 23),
                locationChange: DT.entry11Created,
                expiry: DateTime.utc(2015, 8, 29, 21),
                expires: true,
                usageCount: 3,
              ),
              fields: sampleFields,
              binaries: {
                'attachment':
                    '6de2ccb163da5f925ea9cdc1298b7c1bd6f7afbbbed41f3d52352f9efbd9db8a',
              },
              autoType: KdbxAutoType(
                enabled: true,
                obfuscation: AutoTypeObfuscationOptions.none,
                defaultSequence: '{USERNAME}{TAB}{PASSWORD}{ENTER}{custom}',
                items: [
                  KdbxAutoTypeItem(
                    window: 'chrome',
                    keystrokeSequence:
                        '{USERNAME}{TAB}{PASSWORD}{ENTER}{custom}{custom-key}',
                  ),
                ],
              ),
            ),
          ],
        ),
        TestGroup(
          uuid: KdbxUuid.fromString('QF6yl7EUVk6+NgdJtyl3sg=='),
          name: 'Windows',
          notes: '',
          icon: 38,
          isExpanded: false,
          lastTopVisibleEntry: KdbxUuid.zero,
          groups: [
            TestGroup(
              uuid: KdbxUuid.fromString('sBLFdcEHtkGNvwUCcfQVKg=='),
              name: 'Network',
            ),
          ],
        ),
        TestGroup(
          uuid: KdbxUuid.fromString('nBnVmN3JYkalgnMu9fVcXQ=='),
          name: 'Internet',
          notes: '',
          icon: 1,
          isExpanded: true,
          lastTopVisibleEntry: KdbxUuid.zero,
        ),
        TestGroup(
            uuid: ID.trash,
            name: 'Recycle Bin',
            notes: '',
            icon: 43,
            isExpanded: false,
            lastTopVisibleEntry: KdbxUuid.zero,
            groups: [
              TestGroup(
                uuid: KdbxUuid.fromString('PU0xw1tiT0yghaLZQwTIZQ=='),
                name: 'eMail',
              ),
              TestGroup(
                uuid: KdbxUuid.fromString('9SnhkxSm6UiOkDrLT8/elQ=='),
                name: 'Homebanking',
              ),
            ],
            entries: [
              TestEntry(uuid: KdbxUuid.fromString('/9/dBmG2B029Pbc6zUBINQ==')),
            ]),
      ],
      entries: [
        TestEntry(uuid: ID.entry1),
        TestEntry(uuid: KdbxUuid.fromString('+sLLlEODSU2/7ioDy+d1Ew==')),
      ],
    ),
  );
}

List<int> challengeResponse(List<int> challenge) {
  final responses = {
    '011ed85afa703341893596fba2da60b6cacabaa5468a0e9ea74698b901bc89ab':
        'ae7244b336f3360e4669ec9eaf4ddc23785aef03',
    '0ba4bbdf2e44fe56b64136a5086ba3ab814130d8e3fe7ed0e869cc976af6c12a':
        '18350f73193e1c89211921d3016bfe3ddfc54d3e',
  };
  final hexChallenge = hex.encode(challenge);
  final response =
      responses[hexChallenge] ?? '0000000000000000000000000000000000000000';
  return hex.decode(response);
}

void main() {
  group('KDBX database tests', () {
    setUp(() async {
      await TestResources.init();
    });

    test('loads simple file', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);
      final db = KdbxDatabase.fromBytes(
          data: TestResources.demoKdbx, credentials: credentials);
      expect(db.meta.generator, 'KeePass');
      expect(_getTestDb().isEqual(db), true);
    });

    test('checks versions', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);
      final db = KdbxDatabase.fromBytes(
          data: TestResources.demoKdbx, credentials: credentials);
      expect(db.header.version, (3, 1));
      expect(db.header.versionIsAtLeast(1, 0), true);
      expect(db.header.versionIsAtLeast(3, 0), true);
      expect(db.header.versionIsAtLeast(3, 1), true);
      expect(db.header.versionIsAtLeast(3, 2), false);
      expect(db.header.versionIsAtLeast(4, 0), false);
      expect(db.header.versionIsAtLeast(4, 1), false);
      expect(db.header.versionIsAtLeast(4, 2), false);
    });

    test('loads simple xml file', () {
      final credentials =
          KdbxCredentials(password: ProtectedData.fromString(''));
      final xml = utf8.decode(TestResources.demoXml);
      final db =
          KdbxDatabase.fromXmlString(xmlString: xml, credentials: credentials);
      expect(db.meta.generator, 'KeePass');
      expect(_getTestDb().isEqual(db), true);
    });

    test('generates error for malformed xml file', () {
      final credentials =
          KdbxCredentials(password: ProtectedData.fromString(''));
      expect(
          () => KdbxDatabase.fromXmlString(
              xmlString: 'malformed-xml', credentials: credentials),
          throwsA(predicate((e) =>
              e is FileCorruptedError && e.message.contains('bad xml'))));
    });

    test('loads utf8 uncompressed file', () {
      final credentials =
          KdbxCredentials(password: ProtectedData.fromString('пароль'));
      final db = KdbxDatabase.fromBytes(
          data: TestResources.cyrillicKdbx, credentials: credentials);
      expect(db.meta.generator, 'KeePass');
      expect(db.meta.name, 'моя база паролей');
    });

    test('loads a file with binary key', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('test'),
          keyData: TestResources.binKeyKey);
      final db = KdbxDatabase.fromBytes(
          data: TestResources.binKeyKdbx, credentials: credentials);
      expect(db.meta.generator, 'KeePass');
    });

    test('loads a file with empty pass', () {
      final credentials =
          KdbxCredentials(password: ProtectedData.fromString(''));
      final db = KdbxDatabase.fromBytes(
          data: TestResources.emptyPass, credentials: credentials);
      expect(db.meta.generator, 'KeePass');
    });

    test('loads a file with empty pass and key-file', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString(''),
          keyData: TestResources.emptyPassWithKeyFileKey);
      final db = KdbxDatabase.fromBytes(
          data: TestResources.emptyPassWithKeyFile, credentials: credentials);
      expect(db.meta.generator, 'KeePass');
    });

    test('loads a file with no pass and key-file', () {
      final credentials =
          KdbxCredentials(keyData: TestResources.noPassWithKeyFileKey);
      final db = KdbxDatabase.fromBytes(
          data: TestResources.noPassWithKeyFile, credentials: credentials);
      expect(db.meta.generator, 'KeePass');
    });

    test('loads a 32-byte key-file', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('test'),
          keyData: TestResources.key32Key);
      final db = KdbxDatabase.fromBytes(
          data: TestResources.key32, credentials: credentials);
      expect(db.meta.generator, 'KeePass');
    });

    test('loads a 64-byte key-file', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('test'),
          keyData: TestResources.key64Key);
      final db = KdbxDatabase.fromBytes(
          data: TestResources.key64, credentials: credentials);
      expect(db.meta.generator, 'KeePass');
    });

    test('loads a xml-bom key-file', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('test'),
          keyData: TestResources.keyWithBomKey);
      final db = KdbxDatabase.fromBytes(
          data: TestResources.keyWithBom, credentials: credentials);
      expect(db.meta.generator, 'KeePass');
    });

    test('loads a V2 key-file', () {
      final credentials = KdbxCredentials(keyData: TestResources.keyV2Key);
      final db = KdbxDatabase.fromBytes(
          data: TestResources.keyV2, credentials: credentials);
      expect(db.meta.generator, 'KeePass');
    });

    test('successfully loads saved file', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);

      var db = KdbxDatabase.fromBytes(
          data: TestResources.demoKdbx, credentials: credentials);
      expect(db.meta.generator, 'KeePass');

      final testDb = _getTestDb();
      expect(testDb.isEqual(db), true);

      final data = db.save();
      db = KdbxDatabase.fromBytes(data: data, credentials: credentials);
      expect(db.meta.generator, 'KPassLib');
      expect(testDb.isEqual(db), true);
    });

    test('loads kdbx4 file with argon2 kdf', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);

      var db = KdbxDatabase.fromBytes(
          data: TestResources.argon2, credentials: credentials);
      expect(db.meta.generator, 'KeePass');
      final testDb = _getTestDb();
      expect(testDb.isEqual(db), true);

      final data = db.save();
      db = KdbxDatabase.fromBytes(data: data, credentials: credentials);
      expect(db.meta.generator, 'KPassLib');
      expect(testDb.isEqual(db), true);
    });

    test('loads kdbx4 file with argon2id kdf', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);

      var db = KdbxDatabase.fromBytes(
          data: TestResources.argon2id, credentials: credentials);
      expect(db.meta.generator, 'KeePass');
      final testDb = _getTestDb();
      expect(testDb.isEqual(db), true);

      final data = db.save();
      db = KdbxDatabase.fromBytes(data: data, credentials: credentials);
      expect(db.meta.generator, 'KPassLib');
      expect(testDb.isEqual(db), true);
    });

    test('loads kdbx3 file with chacha20', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);

      var db = KdbxDatabase.fromBytes(
          data: TestResources.aesChaCha, credentials: credentials);
      final testDb = _getTestDb();
      expect(testDb.isEqual(db), true);

      final data = db.save();
      db = KdbxDatabase.fromBytes(data: data, credentials: credentials);
      expect(db.meta.generator, 'KPassLib');
      expect(db.header.dataCipherUuid?.string, CipherId.chaCha20);
      expect(testDb.isEqual(db), true);
    });

    test('loads kdbx4 file with aes kdf', () {
      final credentials =
          KdbxCredentials(password: ProtectedData.fromString('demo'));

      var db = KdbxDatabase.fromBytes(
          data: TestResources.aesKdfKdbx4, credentials: credentials);
      expect(db.header.dataCipherUuid?.string, CipherId.aes);

      final data = db.save();
      db = KdbxDatabase.fromBytes(data: data, credentials: credentials);
      expect(db.meta.generator, 'KPassLib');
      expect(db.header.dataCipherUuid?.string, CipherId.aes);
    });

    test('loads kdbx4 file with argon2 kdf and chacha20 encryption', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);

      var db = KdbxDatabase.fromBytes(
          data: TestResources.argon2ChaCha, credentials: credentials);
      expect(db.meta.generator, 'KeePass');
      final testDb = _getTestDb();
      expect(testDb.isEqual(db), true);

      final data = db.save();
      db = KdbxDatabase.fromBytes(data: data, credentials: credentials);
      expect(db.meta.generator, 'KPassLib');
      expect(db.header.dataCipherUuid?.string, CipherId.chaCha20);
      expect(testDb.isEqual(db), true);
    });

    test('loads kdbx3 file with challenge-response', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          challengeResponse: challengeResponse);
      final db = KdbxDatabase.fromBytes(
          data: TestResources.yubikey3, credentials: credentials);
      expect(db.meta.generator, 'Strongbox');
    });

    test('loads a kdbx4 file with challenge-response', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          challengeResponse: challengeResponse);
      final db = KdbxDatabase.fromBytes(
          data: TestResources.yubikey4, credentials: credentials);
      expect(db.meta.generator, 'KeePassXC');
    });

    test('upgrades file to latest version', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);

      var db = KdbxDatabase.fromBytes(
          data: TestResources.demoKdbx, credentials: credentials);
      expect(db.meta.generator, 'KeePass');
      final testDb = _getTestDb();
      expect(testDb.isEqual(db), true);

      db.upgrade();
      final data = db.save();
      db = KdbxDatabase.fromBytes(data: data, credentials: credentials);
      expect(db.meta.generator, 'KPassLib');
      expect(db.header.version, (4, 1));
      expect(
          db.header.kdfParameters?.get('\$UUID'), base64.decode(KdfId.argon2));
      expect(testDb.isEqual(db), true);
    });

    test('upgrades file to latest version with aes kdf', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);

      var db = KdbxDatabase.fromBytes(
          data: TestResources.demoKdbx, credentials: credentials);
      expect(db.meta.generator, 'KeePass');
      final testDb = _getTestDb();
      expect(testDb.isEqual(db), true);

      db.upgrade();
      db.kdf = KdfId.aes;
      final data = db.save();
      db = KdbxDatabase.fromBytes(data: data, credentials: credentials);
      expect(db.meta.generator, 'KPassLib');
      expect(db.header.version, (4, 1));
      expect(db.header.kdfParameters?.get('\$UUID'), base64.decode(KdfId.aes));
      expect(testDb.isEqual(db), true);
    });

    test('upgrades file to latest version with argon2id kdf', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);

      var db = KdbxDatabase.fromBytes(
          data: TestResources.demoKdbx, credentials: credentials);
      expect(db.meta.generator, 'KeePass');
      final testDb = _getTestDb();
      expect(testDb.isEqual(db), true);

      db.upgrade();
      db.kdf = KdfId.argon2id;
      final data = db.save();
      db = KdbxDatabase.fromBytes(data: data, credentials: credentials);
      expect(db.meta.generator, 'KPassLib');
      expect(db.header.version, (4, 1));
      expect(db.header.kdfParameters?.get('\$UUID'),
          base64.decode(KdfId.argon2id));
      expect(testDb.isEqual(db), true);
    });

    test('downgrades file to V3', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);

      var db = KdbxDatabase.fromBytes(
          data: TestResources.demoKdbx, credentials: credentials);
      expect(db.meta.generator, 'KeePass');
      final testDb = _getTestDb();
      expect(testDb.isEqual(db), true);

      db.version = (3, 1);
      final data = db.save();
      db = KdbxDatabase.fromBytes(data: data, credentials: credentials);
      expect(db.meta.generator, 'KPassLib');
      expect(db.header.version, (3, 1));
      expect(testDb.isEqual(db), true);
    });

    test('saves kdbx4 to xml and loads it back', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);

      var db = KdbxDatabase.fromBytes(
          data: TestResources.demoKdbx, credentials: credentials);
      expect(db.meta.generator, 'KeePass');
      final testDb = _getTestDb();
      expect(testDb.isEqual(db), true);

      db.upgrade();
      final data = db.exportToXmlString(pretty: true);
      db =
          KdbxDatabase.fromXmlString(xmlString: data, credentials: credentials);
      expect(db.meta.generator, 'KPassLib');
      expect(testDb.isEqual(db), true);
    });

    test('saves and loads custom data', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);

      var db = KdbxDatabase.fromBytes(
          data: TestResources.demoKdbx, credentials: credentials);
      expect(db.meta.generator, 'KeePass');
      final testDb = _getTestDb();
      expect(testDb.isEqual(db), true);

      db.upgrade();

      final customIcon = KdbxUuid.random();
      db.root.groups.first.customData = KdbxCustomData()
        ..map = {'custom': KdbxCustomItem(value: 'group')};
      db.root.groups.first.customIcon = customIcon;
      db.root.entries.first.customData = KdbxCustomData()
        ..map = {'custom': KdbxCustomItem(value: 'entry')};

      final data = db.save();
      db = KdbxDatabase.fromBytes(data: data, credentials: credentials);
      expect(db.meta.generator, 'KPassLib');
      expect(db.header.version, (4, 1));
      expect(db.root.groups.first.customData?.map['custom']?.value, 'group');
      expect(db.root.groups.first.customIcon?.string, customIcon.string);
      expect(db.root.entries.first.customData?.map['custom']?.value, 'entry');
      expect(testDb.isEqual(db), true);
    });

    test('creates new database', () {
      final keyFile = KdbxCredentials.createRandomKeyFile(version: 1);
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'), keyData: keyFile);

      var db = KdbxDatabase.create(credentials: credentials, name: 'example');
      final subGroup = db.createGroup(parentGroup: db.root, name: 'subgroup');
      final entry = db.createEntry(parent: subGroup);
      db.meta.customData = KdbxCustomData()
        ..map.addAll({'key': KdbxCustomItem(value: 'val')});
      entry.fields.addAll({
        'Title': KdbxTextField.fromText(text: 'title'),
        'UserName': KdbxTextField.fromText(text: 'user'),
        'Password': KdbxTextField.fromText(text: 'pass', protected: true),
        'Notes': KdbxTextField.fromText(text: 'notes'),
        'URL': KdbxTextField.fromText(text: 'url')
      });
      final binary = ProtectedBinary(
          protectedData: ProtectedData.fromString('bin.txt content'));
      final ref = db.binaries.add(binary);
      entry.binaries['bin.txt'] = ref;
      entry.pushHistory();
      entry.fields.addAll({
        'Title': KdbxTextField.fromText(text: 'newtitle'),
        'UserName': KdbxTextField.fromText(text: 'newuser'),
        'Password': KdbxTextField.fromText(text: 'newpass', protected: true),
        'CustomPlain': KdbxTextField.fromText(text: 'custom-plain'),
        'CustomProtected':
            KdbxTextField.fromText(text: 'custom-protected', protected: true)
      });
      entry.times.touch();

      final ab = db.save();
      db = KdbxDatabase.fromBytes(data: ab, credentials: credentials);

      expect(db.meta.generator, 'KPassLib');
      expect(db.meta.customData.map['key']?.value, 'val');
      expect(db.groups.length, 1);
      expect(db.root.groups.length, 2);
      expect(db.getGroup(uuid: db.meta.recycleBinUuid), db.root.groups.first);
    });

    test('creates random keyfile v2', () {
      final keyFile = KdbxCredentials.createRandomKeyFile(version: 2);
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'), keyData: keyFile);
      var db = KdbxDatabase.create(credentials: credentials, name: 'example');

      final keyFileStr = utf8.decode(Uint8List.fromList(keyFile));
      expect(keyFileStr.contains('<Version>2.0</Version>'), true);

      final ab = db.save();
      db = KdbxDatabase.fromBytes(data: ab, credentials: credentials);
      expect(db.meta.generator, 'KPassLib');
    });

    test('generates error for bad file', () {
      expect(
          () => KdbxDatabase.fromBytes(
              data: utf8.encode('file'), credentials: KdbxCredentials()),
          throwsA(predicate(
              (e) => e is FileCorruptedError && e.message.contains('data'))));
    });

    test('generates an error for too high major version', () {
      final file = List<int>.from(TestResources.demoKdbx);
      file[10] = 5;
      expect(
          () => KdbxDatabase.fromBytes(
              data: file, credentials: KdbxCredentials()),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('invalid version'))));
    });

    test('generates an error for too low major version', () {
      final file = List<int>.from(TestResources.demoKdbx);
      file[10] = 5;
      expect(
          () => KdbxDatabase.fromBytes(
              data: file, credentials: KdbxCredentials()),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('invalid version'))));
    });

    test('generates an error for too high minor version', () {
      final file = List<int>.from(TestResources.demoKdbx);
      file[11] = 10;
      expect(
          () => KdbxDatabase.fromBytes(
              data: file, credentials: KdbxCredentials()),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('invalid version'))));
    });

    test('generates error for bad header hash', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);

      final file = List<int>.from(TestResources.argon2);
      file[254] = 0;
      expect(
          () => KdbxDatabase.fromBytes(data: file, credentials: credentials),
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('header hash mismatch'))));
    });

    test('generates error for bad header hmac', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);

      final file = List<int>.from(TestResources.argon2);
      file[286] = 0;
      expect(
          () => KdbxDatabase.fromBytes(data: file, credentials: credentials),
          throwsA(predicate((e) =>
              e is InvalidCredentialsError &&
              e.message.contains('invalid key'))));
    });

    test('generates loadXml error for bad data', () {
      expect(
          () => KdbxDatabase.fromXmlString(
              xmlString: '', credentials: KdbxCredentials()),
          throwsA(predicate((e) =>
              e is FileCorruptedError && e.message.contains('bad xml'))));
    });

    test('generates error for bad password', () {
      expect(
          () => KdbxDatabase.fromBytes(
              data: TestResources.demoKdbx,
              credentials: KdbxCredentials(
                  password: ProtectedData.fromString('badpass'))),
          throwsA(predicate((e) =>
              e is InvalidCredentialsError &&
              e.message.contains('invalid key'))));
    });

    test('deletes and restores an entry', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);

      final db = KdbxDatabase.fromBytes(
          data: TestResources.demoKdbx, credentials: credentials);

      final parentGroup = db.root.groups[1];
      final group = parentGroup.groups.last;
      final recycleBin = db.getGroup(uuid: db.meta.recycleBinUuid);
      final recycleBinLength = recycleBin!.groups.length;
      final groupLength = parentGroup.groups.length;
      db.remove(group);
      expect(recycleBin.groups.length, recycleBinLength + 1);
      expect(parentGroup.groups.length, groupLength - 1);

      db.move(item: group, target: parentGroup);
      expect(recycleBin.groups.length, recycleBinLength);
      expect(_getTestDb().isEqual(db), true);
    });

    test('changes group order', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);

      final db = KdbxDatabase.fromBytes(
          data: TestResources.demoKdbx, credentials: credentials);

      final root = db.root;
      expect(root.groups.length > 3, true);
      final groupNames = root.groups.map((g) => g.uuid).toList();
      db.move(item: root.groups[2], target: root, index: 1);
      groupNames.swap(1, 2);
      final newGroupNames = root.groups.map((g) => g.uuid).toList();
      expect(groupNames, newGroupNames);

      db.move(item: root.groups[2], target: root, index: 1);
      expect(_getTestDb().isEqual(db), true);
    });

    test('deletes entry without recycle bin', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);

      final db = KdbxDatabase.fromBytes(
          data: TestResources.demoKdbx, credentials: credentials);

      final group = db.root.groups[1].groups.last;
      final deletedObjectsLength = db.deletedObjects.length;
      db.meta.recycleBinEnabled = false;
      db.remove(group);
      expect(db.deletedObjects.length, deletedObjectsLength + 1);
      expect(db.deletedObjects.keys.last, group.uuid);
    });

    test('creates a recycle bin if it is enabled but not created', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);

      final db = KdbxDatabase.fromBytes(
          data: TestResources.demoKdbx, credentials: credentials);

      final parentGroup = db.root.groups[1];
      final groupLength = parentGroup.groups.length;
      final group = parentGroup.groups.last;

      db.meta.recycleBinEnabled = true;
      db.meta.recycleBinUuid = null;
      db.remove(group);
      expect(db.meta.recycleBinUuid == null, false);

      final recycleBin = db.getGroup(uuid: db.meta.recycleBinUuid);
      expect(recycleBin == null, false);
      expect(recycleBin!.groups.length, 1);
      expect(group.groups.length, groupLength - 1);
    });

    test('saves db to xml', () {
      final keyFile = KdbxCredentials.createRandomKeyFile(version: 2);
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'), keyData: keyFile);
      final db = KdbxDatabase.create(credentials: credentials, name: 'example');

      final subGroup = db.createGroup(parentGroup: db.root, name: 'subgroup');
      final entry = db.createEntry(parent: subGroup);
      entry.fields.addAll({
        'Title': KdbxTextField.fromText(text: 'title'),
        'UserName': KdbxTextField.fromText(text: 'user'),
        'Password': KdbxTextField.fromText(text: 'pass', protected: true),
        'Notes': KdbxTextField.fromText(text: 'notes'),
        'URL': KdbxTextField.fromText(text: 'url')
      });
      entry.times.touch();

      final xml = db.exportToXmlString();
      expect(xml.contains('<Value ProtectInMemory="True">pass</Value>'), true);
    });

    test('cleanups by history rules', () {
      final keyFile = KdbxCredentials.createRandomKeyFile(version: 2);
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'), keyData: keyFile);
      final db = KdbxDatabase.create(credentials: credentials, name: 'example');

      final subGroup = db.createGroup(parentGroup: db.root, name: 'subgroup');
      final entry = db.createEntry(parent: subGroup);

      for (var i = 0; i < 3; i++) {
        entry.fields['Title'] = KdbxTextField.fromText(text: i.toString());
        entry.pushHistory();
      }

      expect((entry.history.first.fields['Title'] as PlainTextField).text, '0');
      expect(entry.history.length, 3);

      db.cleanup(history: true);
      expect(entry.history.length, 3);
      for (var i = 3; i < 10; i++) {
        entry.fields['Title'] = KdbxTextField.fromText(text: i.toString());
        entry.pushHistory();
      }
      expect((entry.history.first.fields['Title'] as PlainTextField).text, '0');
      expect(entry.history.length, 10);
      expect((entry.history.first.fields['Title'] as PlainTextField).text, '0');

      db.cleanup(history: true);
      expect((entry.history.first.fields['Title'] as PlainTextField).text, '0');
      expect(entry.history.length, 10);
      for (var i = 10; i < 11; i++) {
        entry.fields['Title'] = KdbxTextField.fromText(text: i.toString());
        entry.pushHistory();
      }
      expect(entry.history.length, 11);

      db.cleanup(history: true);
      expect((entry.history.first.fields['Title'] as PlainTextField).text, '1');
      expect(entry.history.length, 10);
      for (var i = 11; i < 20; i++) {
        entry.fields['Title'] = KdbxTextField.fromText(text: i.toString());
        entry.pushHistory();
      }

      db.cleanup(history: true);
      expect(
          (entry.history.first.fields['Title'] as PlainTextField).text, '10');
      expect(entry.history.length, 10);
      for (var i = 20; i < 30; i++) {
        entry.fields['Title'] = KdbxTextField.fromText(text: i.toString());
        entry.pushHistory();
      }
      db.meta.historyMaxItems = null;

      db.cleanup(history: true);
      expect(
          (entry.history.first.fields['Title'] as PlainTextField).text, '10');
      expect(entry.history.length, 20);

      db.cleanup();
      expect(entry.history.length, 20);
      db.meta.historyMaxItems = null;

      db.cleanup(history: true);
      expect(
          (entry.history.first.fields['Title'] as PlainTextField).text, '10');
      expect(entry.history.length, 20);
    });

    test('cleanups custom icons', () {
      final keyFile = KdbxCredentials.createRandomKeyFile(version: 2);
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'), keyData: keyFile);
      final db = KdbxDatabase.create(credentials: credentials, name: 'example');

      final subGroup = db.createGroup(parentGroup: db.root, name: 'subgroup');
      final entry = db.createEntry(parent: subGroup);

      final ids = List.generate(6, (_) => KdbxUuid.random());
      final icons = List.generate(6, (i) => KdbxCustomIcon(data: [i]));

      for (var i = 0; i < 3; i++) {
        entry.fields['Title'] = KdbxTextField.fromText(text: i.toString());
        entry.customIcon = ids.first;
        entry.pushHistory();
      }
      entry.customIcon = ids[1];
      subGroup.customIcon = ids[2];

      ids.forEachIndexed((i, id) {
        db.meta.customIcons[id] = icons[i];
      });

      db.cleanup(icons: true);
      expect(
        db.meta.customIcons,
        {ids[0]: icons[0], ids[1]: icons[1], ids[2]: icons[2]},
      );
    });

    test('cleanups binaries', () {
      final keyFile = KdbxCredentials.createRandomKeyFile(version: 2);
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'), keyData: keyFile);
      final db = KdbxDatabase.create(credentials: credentials, name: 'example');

      final subGroup = db.createGroup(parentGroup: db.root, name: 'subgroup');
      final entry = db.createEntry(parent: subGroup);

      final binaries =
          List.generate(5, (i) => PlainBinary(data: [i], compressed: false));

      for (var i = 0; i < 3; i++) {
        entry.fields['Title'] = KdbxTextField.fromText(text: i.toString());
        final ref = db.binaries.add(binaries[0]);
        entry.binaries['bin'] = ref;
        entry.pushHistory();
      }

      final ref = db.binaries.add(binaries[1]);
      entry.binaries['bin'] = ref;

      db.binaries.add(binaries[2]);
      db.binaries.add(binaries[3]);
      db.binaries.add(binaries[4]);

      db.cleanup(binaries: true);
      expect(db.binaries.all, binaries.sublist(0, 2));
    });

    test('imports an entry from another file', () {
      final credentials = KdbxCredentials(
          password: ProtectedData.fromString('demo'),
          keyData: TestResources.demoKey);
      var db = KdbxDatabase.create(credentials: credentials, name: 'example');
      var sourceDb = KdbxDatabase.fromBytes(
          data: TestResources.demoKdbx, credentials: credentials);

      final sourceEntryWithCustomIcon = sourceDb.root.entries.first;
      final sourceEntryWithBinaries = sourceDb.root.groups.first.entries.first;

      expect(sourceDb.root.entries.length, 2);
      expect(sourceEntryWithCustomIcon.customIcon != null, true);
      expect(sourceEntryWithBinaries.binaries.keys, ['attachment']);

      final importedEntryWithCustomIcon =
          db.importEntry(sourceEntryWithCustomIcon, db.root, sourceDb);
      final importedEntryWithBinaries =
          db.importEntry(sourceEntryWithBinaries, db.root, sourceDb);

      expect(importedEntryWithCustomIcon.uuid != sourceEntryWithCustomIcon.uuid,
          true);
      expect(
          importedEntryWithBinaries.uuid != sourceEntryWithBinaries.uuid, true);

      final ab = db.save();
      db = KdbxDatabase.fromBytes(data: ab, credentials: credentials);
      expect(db.root.entries.length, 2);

      final withCustomIcon = db.root.entries[0];
      final withBinaries = db.root.entries[1];

      expect(withCustomIcon.uuid, importedEntryWithCustomIcon.uuid);
      expect(withCustomIcon.customIcon != null, true);
      expect(db.meta.customIcons.containsKey(withCustomIcon.customIcon), true);

      expect(withBinaries.uuid, importedEntryWithBinaries.uuid);
      expect(withBinaries.binaries.keys, ['attachment']);
    });

    test('creates missing uuids', () {
      final credentials =
          KdbxCredentials(password: ProtectedData.fromString(''));
      final xml = utf8.decode(TestResources.emptyUuidXml);
      final db =
          KdbxDatabase.fromXmlString(xmlString: xml, credentials: credentials);
      expect(db.meta.generator, 'KeePass');
      expect(db.groups.length, 1);
      final entry = db.root.groups.first.entries.first;
      expect(entry.history.isNotEmpty, true);
    });

    test('supports KDBX4.1 features', () {
      check(KdbxDatabase db) {
        final groupWithTags = db.root.groups.first.groups.first;
        expect(groupWithTags.name, 'With tags');
        expect(groupWithTags.tags, ['Another tag', 'Tag1']);
        expect(groupWithTags.previousParent, null);

        final regularEntry = db.root.entries[0];
        expect(regularEntry.qualityCheck, null);

        final entryWithDisabledPasswordQuality = db.root.entries[1];
        expect(
            (entryWithDisabledPasswordQuality.fields['Title'] as PlainTextField)
                .text,
            'DisabledQ');
        expect(entryWithDisabledPasswordQuality.qualityCheck, false);

        final previousParentGroup = db.root.groups.first.groups[1];
        expect(previousParentGroup.name, 'Inside');

        final groupMovedFromInside = db.root.groups.first.groups[2];
        expect(groupMovedFromInside.name, 'New group was inside');
        expect(previousParentGroup.uuid, groupMovedFromInside.previousParent);

        final entryMovedFromInside = db.root.groups.first.entries[0];
        expect((entryMovedFromInside.fields['Title'] as PlainTextField).text,
            'Was inside');
        expect(previousParentGroup.uuid, entryMovedFromInside.previousParent);

        expect(db.meta.customIcons.length, 2);
        final icon1 = db
            .meta.customIcons[KdbxUuid.fromString('3q2nWI0en0W/wvhaCFJsnw==')];
        expect(icon1?.name, 'Bulb icon');
        expect(icon1?.modified.time, DateTime.utc(2021, 5, 5, 18, 28, 34));

        expect(db.meta.customData.map.length, 4);
        final item = db.meta.customData.map['Test_A'];
        expect(item?.value, 'NmL56onQIqdk1WSt');
        expect(item?.modification.time, DateTime.utc(2021, 1, 20, 18, 10, 44));
      }

      final credentials =
          KdbxCredentials(password: ProtectedData.fromString('test'));
      var db = KdbxDatabase.fromBytes(
          data: TestResources.kdbx41, credentials: credentials);
      check(db);

      final xml = db.exportToXmlString();
      db = KdbxDatabase.fromXmlString(xmlString: xml, credentials: credentials);
      check(db);
    });
  });
}
