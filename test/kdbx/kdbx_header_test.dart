import 'package:convert/convert.dart';
import 'package:kpasslib/kpasslib.dart';
import 'package:kpasslib/src/utils/byte_utils.dart';
import 'package:kpasslib/src/utils/parameters_map.dart';
import 'package:test/test.dart';

void main() {
  group('Header unit tests', () {
    test('writes and reads header v3', () {
      final credentials = KdbxCredentials();
      final header = KdbxHeader.create(credentials: credentials);
      expect(header.version, (4, 1));

      header.version = (3, 1);
      expect(header.version, (3, 1));

      header.masterSeed = [1, 1, 1, 1];
      header.transformSeed = [2, 2, 2, 2];
      header.streamStartBytes = [3, 3, 3, 3];
      header.protectedStreamKey = [4, 4, 4, 4];
      header.encryptionIV = [5, 5];

      final bytes = header.bytes;
      final reader = BytesReader(bytes);
      final newHeader =
          KdbxHeader.fromBytes(credentials: credentials, reader: reader);

      expect(newHeader.version, header.version);
      expect(newHeader.dataCipherUuid?.string, CipherId.aes);
      expect(newHeader.crsAlgorithm, CrsAlgorithm.salsa20);
      expect(newHeader.compression, CompressionAlgorithm.gzip);
      expect(newHeader.masterSeed, header.masterSeed);
      expect(newHeader.transformSeed, header.transformSeed);
      expect(newHeader.streamStartBytes, header.streamStartBytes);
      expect(newHeader.protectedStreamKey, header.protectedStreamKey);
      expect(newHeader.encryptionIV, header.encryptionIV);
      expect(newHeader.kdfParameters, null);
      expect(newHeader.publicCustomData, null);
    });

    test('writes and reads header v4', () {
      final credentials = KdbxCredentials();
      final header = KdbxHeader.create(credentials: credentials);

      header.binaries.add(PlainBinary(data: [1, 2], compressed: false));
      header.binaries.add(
          ProtectedBinary(protectedData: ProtectedData.fromBytes([1, 2, 3])));

      expect(header.version, (4, 1));
      header.masterSeed = [1, 1, 1, 1];
      header.transformSeed = [2, 2, 2, 2];
      header.streamStartBytes = [3, 3, 3, 3];
      header.protectedStreamKey = [4, 4, 4, 4];
      header.encryptionIV = [5, 5];
      header.kdfParameters!.add(
        key: 'S',
        type: ParameterType.bytes,
        value: [6, 6, 6, 6],
      );
      header.publicCustomData = ParametersMap()
        ..add(
          key: 'custom',
          type: ParameterType.string,
          value: 'val',
        );

      final newHeader = KdbxHeader.fromBytes(
          credentials: credentials, reader: BytesReader(header.bytes));

      expect(newHeader.version, header.version);
      expect(newHeader.dataCipherUuid?.string, CipherId.aes);
      expect(newHeader.crsAlgorithm, null);
      expect(newHeader.compression, CompressionAlgorithm.gzip);
      expect(newHeader.masterSeed, [1, 1, 1, 1]);
      expect(newHeader.transformSeed, null);
      expect(newHeader.streamStartBytes, null);
      expect(newHeader.protectedStreamKey, null);
      expect(newHeader.encryptionIV, [5, 5]);
      expect(
          KdbxUuid.fromBytes(
                  newHeader.kdfParameters!.get('\$UUID') as List<int>)
              .string,
          KdfId.argon2);
      expect(newHeader.kdfParameters?.get('S'), [6, 6, 6, 6]);
      expect(newHeader.kdfParameters?.get('P'), 1);
      expect(newHeader.kdfParameters?.get('V'), 0x13);
      expect(newHeader.kdfParameters?.get('I'), 2);
      expect(newHeader.kdfParameters?.get('M'), 1024 * 1024);
      expect(newHeader.publicCustomData?.get('custom'), 'val');
      expect(newHeader.binaries.all, []);

      newHeader.readInnerHeader(BytesReader(header.innerBytes));

      expect(newHeader.crsAlgorithm, CrsAlgorithm.chaCha20);
      expect(newHeader.protectedStreamKey, [4, 4, 4, 4]);

      final oldBinaries = header.binaries.all;
      final newBinaries = newHeader.binaries.all;
      expect(newBinaries.length, oldBinaries.length);
      expect(newBinaries[0].data, oldBinaries[0].data);
      expect(newBinaries[1].data, oldBinaries[1].data);
      expect(newHeader.binaries.getByRef(BinaryReference(0))?.data,
          oldBinaries[0].data);
      expect(newHeader.binaries.getByRef(BinaryReference(1))?.data,
          oldBinaries[1].data);
    });

    test('generates salts v3', () {
      final credentials = KdbxCredentials();
      final header = KdbxHeader.create(credentials: credentials);
      header.version = (3, 1);
      header.generateSalts();

      expect(header.masterSeed?.length, 32);
      expect(header.transformSeed?.length, 32);
      expect(header.streamStartBytes?.length, 32);
      expect(header.protectedStreamKey?.length, 32);
      expect(header.encryptionIV?.length, 16);
    });

    test('generates salts v4', () {
      final credentials = KdbxCredentials();
      final header = KdbxHeader.create(credentials: credentials);
      header.version = (4, 1);
      header.dataCipherUuid = KdbxUuid.fromString(CipherId.chaCha20);
      header.generateSalts();

      expect(header.protectedStreamKey?.length, 64);
      expect((header.kdfParameters?.get('S') as List<int>).length, 32);
      expect(header.encryptionIV?.length, 12);

      header.dataCipherUuid = KdbxUuid.fromString(CipherId.aes);
      header.generateSalts();
      expect(header.encryptionIV?.length, 16);
    });

    test('skips binaries for v3', () {
      final credentials = KdbxCredentials();
      final header = KdbxHeader.create(credentials: credentials);
      header.masterSeed = [];
      header.encryptionIV = [];
      header.binaries.add(PlainBinary(data: [1], compressed: false));
      header.version = (3, 1);
      header.transformSeed = [];
      header.protectedStreamKey = [];
      header.streamStartBytes = [];

      final newHeader = KdbxHeader.fromBytes(
          credentials: credentials, reader: BytesReader(header.bytes));
      expect(newHeader.binaries.all.isEmpty, true);
    });

    test('writes header without public custom data', () {
      final credentials = KdbxCredentials();
      final header = KdbxHeader.create(credentials: credentials);
      header.binaries.add(PlainBinary(data: [1], compressed: false));

      header.version = KdbxHeader.defaultVersion;
      header.generateSalts();

      final newHeader = KdbxHeader.fromBytes(
          credentials: credentials, reader: BytesReader(header.bytes));
      expect(newHeader.publicCustomData, null);
    });

    test('validates header cipher', () {
      final credentials = KdbxCredentials();
      final header = KdbxHeader.create(credentials: credentials);
      header.version = KdbxHeader.defaultVersion;
      header.generateSalts();
      header.dataCipherUuid = null;
      expect(
          () => header.bytes,
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('no cipher in header'))));
    });

    test('validates master seed cipher', () {
      final credentials = KdbxCredentials();
      final header = KdbxHeader.create(credentials: credentials);
      header.version = KdbxHeader.defaultVersion;
      header.generateSalts();
      header.masterSeed = null;
      expect(
          () => header.bytes,
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('no master seed in header'))));
    });

    test('validates header encryption iv', () {
      final credentials = KdbxCredentials();
      final header = KdbxHeader.create(credentials: credentials);
      header.version = KdbxHeader.defaultVersion;
      header.generateSalts();
      header.encryptionIV = null;
      expect(
          () => header.bytes,
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('no encryption iv in header'))));
    });

    test('validates header kdf parameters', () {
      final credentials = KdbxCredentials();
      final header = KdbxHeader.create(credentials: credentials);
      header.version = KdbxHeader.defaultVersion;
      header.generateSalts();
      header.kdfParameters = null;
      expect(
          () => header.bytes,
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('no kdf parameters in header'))));
    });

    test('validates header transform seed', () {
      final credentials = KdbxCredentials();
      final header = KdbxHeader.create(credentials: credentials);
      header.version = (3, 1);
      header.generateSalts();
      header.transformSeed = null;
      expect(
          () => header.bytes,
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('no transform seed in header'))));
    });

    test('validates header key encryption rounds', () {
      final credentials = KdbxCredentials();
      final header = KdbxHeader.create(credentials: credentials);
      header.version = (3, 1);
      header.generateSalts();
      header.keyEncryptionRounds = null;
      expect(
          () => header.bytes,
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('no key encryption rounds in header'))));
    });

    test('validates header protected stream key', () {
      final credentials = KdbxCredentials();
      final header = KdbxHeader.create(credentials: credentials);
      header.version = (3, 1);
      header.generateSalts();
      header.protectedStreamKey = null;
      expect(
          () => header.bytes,
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('no protected stream key in header'))));
    });

    test('validates header stream start bytes', () {
      final credentials = KdbxCredentials();
      final header = KdbxHeader.create(credentials: credentials);
      header.version = (3, 1);
      header.generateSalts();
      header.streamStartBytes = null;
      expect(
          () => header.bytes,
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('no stream start bytes in header'))));
    });

    test('validates header crs algorithm', () {
      final credentials = KdbxCredentials();
      final header = KdbxHeader.create(credentials: credentials);
      header.version = (3, 1);
      header.generateSalts();
      header.crsAlgorithm = null;
      expect(
          () => header.bytes,
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('no crs algorithm in header'))));
    });

    test('validates header crs algorithm', () {
      final credentials = KdbxCredentials();
      final header = KdbxHeader.create(credentials: credentials);
      header.version = (3, 1);
      header.generateSalts();
      header.protectedStreamKey = null;
      expect(
          () => header.bytes,
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('no protected stream key in header'))));
    });

    test('validates inner header crs algorithm', () {
      final credentials = KdbxCredentials();
      final header = KdbxHeader.create(credentials: credentials);
      header.version = KdbxHeader.defaultVersion;
      header.generateSalts();
      header.crsAlgorithm = null;
      expect(
          () => header.innerBytes,
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('no crs algorithm in header'))));
    });

    test('throws error for bad signature', () {
      final credentials = KdbxCredentials();
      final reader = BytesReader(hex.decode('0000000000000000'));
      expect(
          () => KdbxHeader.fromBytes(credentials: credentials, reader: reader),
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('bad header signature'))));
    });

    test('throws error for bad version', () {
      final credentials = KdbxCredentials();
      final reader = BytesReader(hex.decode('03d9a29a67fb4bb501000500'));
      expect(
          () => KdbxHeader.fromBytes(credentials: credentials, reader: reader),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('invalid version'))));
    });

    test('throws error for bad cipher', () {
      final credentials = KdbxCredentials();
      final reader = BytesReader(
          hex.decode('03d9a29a67fb4bb501000400020100000031c1f2e6bf'));
      expect(
          () => KdbxHeader.fromBytes(credentials: credentials, reader: reader),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('bad UUID length'))));
    });

    test('throws error for bad compression flags', () {
      final credentials = KdbxCredentials();
      final reader = BytesReader(
          hex.decode('03d9a29a67fb4bb50100040003200000000111111111'));
      expect(
          () => KdbxHeader.fromBytes(credentials: credentials, reader: reader),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('compression type'))));
    });

    test('throws error for empty files', () {
      final credentials = KdbxCredentials();
      final reader = BytesReader([]);
      expect(
          () => KdbxHeader.fromBytes(credentials: credentials, reader: reader),
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('not enough data'))));
    });

    test('throws error for bad version in setVersion', () {
      final credentials = KdbxCredentials();
      final header = KdbxHeader.create(credentials: credentials);
      expect(
          () => header.version = (2, 0),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('invalid version'))));
    });

    test('throws error for bad KDF in setKdf', () {
      final credentials = KdbxCredentials();
      final header = KdbxHeader.create(credentials: credentials);
      expect(
          () => header.kdf = 'fooo',
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('bad KDF algorithm'))));
    });
  });
}
