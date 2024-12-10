import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:kpasslib/kpasslib.dart';
import 'package:pointycastle/export.dart';

import '../crypto/crypto_utils.dart';
import '../crypto/hmac_block_transform.dart';
import '../crypto/key_encryptor_aes.dart';
import '../crypto/key_encryptor_kdf.dart';
import '../crypto/protect_salt_generator.dart';
import '../utils/byte_utils.dart';
import '../utils/parameters_map.dart';

abstract class _HeaderField {
  ParameterType get type;
  int get id;
}

enum _OuterField implements _HeaderField {
  endOfHeader(type: ParameterType.uInt32),
  comment(type: ParameterType.bytes),
  cipherID(type: ParameterType.bytes),
  compressionFlags(type: ParameterType.uInt32),
  masterSeed(type: ParameterType.bytes),
  transformSeed(type: ParameterType.bytes),
  transformRounds(type: ParameterType.uInt64),
  encryptionIV(type: ParameterType.bytes),
  protectedStreamKey(type: ParameterType.bytes),
  streamStartBytes(type: ParameterType.bytes),
  innerRandomStreamID(type: ParameterType.uInt32),
  kdfParameters(type: ParameterType.bytes),
  publicCustomData(type: ParameterType.bytes);

  const _OuterField({required this.type});

  @override
  final ParameterType type;
  @override
  int get id => index;
}

enum _InnerField implements _HeaderField {
  endOfHeader(type: ParameterType.uInt32),
  innerRandomStreamID(type: ParameterType.uInt32),
  innerRandomStreamKey(type: ParameterType.bytes),
  binary(type: ParameterType.bytes);

  const _InnerField({required this.type});

  @override
  final ParameterType type;
  @override
  int get id => index;
}

/// Represents KDBX header type
class KdbxHeader {
  /// The ID of data cipher.
  KdbxUuid? dataCipherUuid;

  /// The compression algorithm.
  var compression = CompressionAlgorithm.gzip;

  /// The master seed bytes.
  List<int>? masterSeed;

  /// The transform seed bytes.
  List<int>? transformSeed;

  /// The number of encryption rounds.
  int? keyEncryptionRounds;

  /// The encryption initial bytes.
  List<int>? encryptionIV;

  /// The protected stream key bytes.
  List<int>? protectedStreamKey;

  /// The stream start bytes.
  List<int>? streamStartBytes;

  /// The CRS algorithm.
  CrsAlgorithm? crsAlgorithm;

  /// The KDF parameters map.
  ParametersMap? kdfParameters;

  /// The public custom data.
  ParametersMap? publicCustomData;

  /// The master key credentials.
  KdbxCredentials credentials;

  /// The binaries collection.
  final binaries = KdbxBinaries();

  /// The last stable versions used as default.
  static const defaultVersion = (4, 1);

  static const _lastStableVersions = {3: 1, 4: 1};
  static const _defaultKdfAlgo = KdfId.argon2d;
  static const _defaultKdfParallelism = 1;
  static const _defaultKdfIterations = 2;
  static const _defaultKdfMemory = 0x100000;
  static const _defaultKdfVersion = 0x13;
  static const _defaultKdfSaltLength = 32;
  static const _endOfHeader = 0x0d0ad0a;

  ProtectSaltGenerator? _saltGenerator;
  var _version = defaultVersion;
  var _hash = <int>[];

  KdbxHeader._(this.credentials);

  /// Constructs a [KdbxHeader] with [credentials].
  factory KdbxHeader.create({required KdbxCredentials credentials}) {
    final header = KdbxHeader._(credentials);
    header.dataCipherUuid = KdbxUuid.fromString(CipherId.aes);
    header.crsAlgorithm = CrsAlgorithm.chaCha20;
    header.kdfParameters = _createKdfParameters();
    return header;
  }

  /// Constructs a [KdbxHeader]  with [credentials] from [reader] bytes.
  factory KdbxHeader.fromBytes({
    required KdbxCredentials credentials,
    required BytesReader reader,
  }) {
    final header = KdbxHeader._(credentials);

    _readSignature(reader);
    header._readVersion(reader);
    while (header._readField(reader)) {}
    header._validate();
    header._setHash(reader.past);

    return header;
  }

  /// Whether versian is at least [major].[minor].
  bool versionIsAtLeast(int major, int minor) =>
      version.$1 > major || (version.$1 == major && version.$2 >= minor);

  /// Reads inner header from [reader] bytes.
  readInnerHeader(BytesReader reader) {
    while (_readField(reader, isInner: true)) {}
    _validateInner();
  }

  /// The header as bytes list.
  List<int> get bytes {
    final writer = BytesWriter();

    _validate();
    _writeSignature(writer);
    _writeVersion(writer);

    _writeField(writer, _OuterField.cipherID, dataCipherUuid?.bytes);
    _writeField(writer, _OuterField.compressionFlags, compression.index);
    _writeField(writer, _OuterField.masterSeed, masterSeed);
    _writeField(writer, _OuterField.encryptionIV, encryptionIV);

    if (version.$1 < 4) {
      _writeField(writer, _OuterField.transformSeed, transformSeed);
      _writeField(writer, _OuterField.transformRounds, keyEncryptionRounds);
      _writeField(writer, _OuterField.protectedStreamKey, protectedStreamKey);
      _writeField(writer, _OuterField.streamStartBytes, streamStartBytes);
      _writeField(writer, _OuterField.innerRandomStreamID, crsAlgorithm?.value);
    } else {
      _writeField(writer, _OuterField.kdfParameters, kdfParameters?.bytes);
      _writeField(
          writer, _OuterField.publicCustomData, publicCustomData?.bytes, false);
    }

    _writeField(writer, _OuterField.endOfHeader, _endOfHeader);

    final bytes = writer.bytes;
    _setHash(bytes);
    return bytes;
  }

  /// The inner header as bytes list.
  List<int> get innerBytes {
    final writer = BytesWriter();

    _validateInner();
    _writeField(writer, _InnerField.innerRandomStreamID, crsAlgorithm?.value);
    _writeField(writer, _InnerField.innerRandomStreamKey, protectedStreamKey);
    _writeBinaries(writer);
    _writeField(writer, _InnerField.endOfHeader, _endOfHeader);

    return writer.bytes;
  }

  /// The salt generator to provide encryption/decryption salt.
  ProtectSaltGenerator get saltGenerator {
    return _saltGenerator ??= _createSaltGenerator();
  }

  /// Updates encryption values depending on version and parameters.
  generateSalts() {
    masterSeed = CryptoUtils.randomBytes(32);
    if (version.$1 < 4) {
      transformSeed = CryptoUtils.randomBytes(32);
      streamStartBytes = CryptoUtils.randomBytes(32);
      protectedStreamKey = CryptoUtils.randomBytes(32);
    } else {
      if (kdfParameters == null || dataCipherUuid == null) {
        throw InvalidStateError('no kdf params');
      }

      kdfParameters?.add(
        key: 'S',
        type: ParameterType.bytes,
        value: CryptoUtils.randomBytes(32),
      );
      protectedStreamKey = CryptoUtils.randomBytes(64);
    }

    encryptionIV = CryptoUtils.randomBytes(
        dataCipherUuid?.string == CipherId.chaCha20 ? 12 : 16);
    _saltGenerator = null;
  }

  /// The header hash.
  List<int> get hash => _hash;

  /// Whether version is supported by current implementation.
  bool isVersionSupported((int, int) v) {
    final minor = _lastStableVersions[v.$1];
    return minor != null && minor >= v.$2;
  }

  /// The current header KDBX version.
  (int, int) get version => _version;

  set version((int, int) version) {
    if (!isVersionSupported(version)) {
      throw UnsupportedValueError('invalid version');
    }

    _version = version;

    if (version.$1 == 4) {
      kdfParameters ??= _createKdfParameters();
      crsAlgorithm = CrsAlgorithm.chaCha20;
      keyEncryptionRounds = null;
    } else {
      kdfParameters = null;
      crsAlgorithm = CrsAlgorithm.salsa20;
      keyEncryptionRounds = Defaults.keyEncryptionRounds;
    }
  }

  set kdf(String kdf) => kdfParameters = _createKdfParameters(algo: kdf);

  /// The master key for KDBX version 3.x.
  List<int> get masterKeyV3 {
    final transformSeed = this.transformSeed;
    final rounds = keyEncryptionRounds;
    final masterSeed = this.masterSeed;

    if (transformSeed == null || rounds == null || masterSeed == null) {
      throw FileCorruptedError('no header transform parameters');
    }

    final credHash = credentials.hash;
    final challengeResponse = credentials.getChallengeResponse(masterSeed);

    final keyHash = KeyEncryptorAes.transform(
        data: credHash, seed: transformSeed, rounds: rounds);
    CryptoUtils.wipeData(credHash);

    final all = masterSeed + (challengeResponse ?? []) + keyHash;
    CryptoUtils.wipeData(keyHash);
    CryptoUtils.wipeData(challengeResponse);

    final masterKey = SHA256Digest().process(Uint8List.fromList(all));
    CryptoUtils.wipeData(all);

    return masterKey;
  }

  /// Returns the master key for KDBX version 4.x.
  (List<int>, List<int>, List<int>) computeKeysV4([List<int>? source]) {
    final seed = masterSeed;
    if (seed == null || seed.length != 32) {
      throw FileCorruptedError('bad master seed');
    }

    final kdfParams = kdfParameters;
    if (kdfParams == null) {
      throw FileCorruptedError('no kdf params');
    }

    final kdfSalt = kdfParams.get('S');
    if (kdfSalt == null) {
      throw FileCorruptedError('no salt');
    }
    if (kdfSalt is! List<int>) {
      throw FileCorruptedError('invalid salt type');
    }

    final credHash = credentials.getHash(challenge: kdfSalt);
    final encKey =
        KeyEncryptorKdf.encrypt(data: credHash, parameters: kdfParams);
    CryptoUtils.wipeData(credHash);
    if (encKey.length != 32) {
      throw FileCorruptedError('bad derived key');
    }

    final keyWithSeed = seed + encKey;
    CryptoUtils.wipeData(encKey);

    final cipherKey = SHA256Digest().process(Uint8List.fromList(keyWithSeed));
    final hmacKey =
        SHA512Digest().process(Uint8List.fromList(keyWithSeed + [1]));
    CryptoUtils.wipeData(keyWithSeed);

    final keySha =
        HmacBlockTransform.getHmacKey(key: hmacKey, index: 0xffffffffffffffff);
    final hmac = (HMac(SHA256Digest(), 64)
          ..init(KeyParameter(Uint8List.fromList(keySha))))
        .process(Uint8List.fromList(source ?? bytes));

    return (cipherKey, hmacKey, hmac);
  }

  ProtectSaltGenerator _createSaltGenerator() {
    final key = protectedStreamKey;
    final algo = crsAlgorithm;

    if (key == null || algo == null) {
      throw InvalidStateError('insufficient header parameters');
    }

    return ProtectSaltGenerator.fromKey(key: key, algorithm: algo);
  }

  _writeBinaries(BytesWriter writer) {
    for (final item in binaries.all) {
      final binary = item;
      final isProtected = binary is ProtectedBinary;
      final binaryData = [(isProtected ? 1 : 0)] + binary.data;
      _writeField(writer, _InnerField.binary, binaryData);
      CryptoUtils.wipeData(binaryData);
    }
  }

  _writeField(BytesWriter writer, _HeaderField field, Object? value,
      [bool errorOnNull = true]) {
    if (value == null) {
      if (errorOnNull) {
        throw InvalidStateError('$field is not set');
      } else {
        return;
      }
    }

    final (bool valid, Function write) = switch (field.type) {
      ParameterType.uInt32 => (value is int, writer.writeUint32),
      ParameterType.uInt64 => (value is int, writer.writeUint64),
      _ => (value is List<int>, writer.writeBytes)
    };

    if (!valid) {
      throw InvalidStateError(
          'incorrect value type of ${value.runtimeType} for $field');
    }

    writer.writeUint8(field.id);
    _writeFieldSize(
        writer, value is List<int> ? value.length : field.type.size);
    write(value);
  }

  _writeFieldSize(BytesWriter writer, int size) {
    version.$1 >= 4 ? writer.writeUint32(size) : writer.writeUint16(size);
  }

  _writeSignature(BytesWriter writer) {
    writer.writeUint32(Signatures.fileMagic);
    writer.writeUint32(Signatures.sig2Kdbx);
  }

  _writeVersion(BytesWriter writer) {
    writer.writeUint16(version.$2);
    writer.writeUint16(version.$1);
  }

  static ParametersMap _createKdfParameters({String algo = _defaultKdfAlgo}) {
    final parameters = ParametersMap();
    final salt = CryptoUtils.randomBytes(_defaultKdfSaltLength);
    parameters.addAll([
      ('\$UUID', ParameterType.bytes, base64.decode(algo)),
      ('S', ParameterType.bytes, salt)
    ]);

    switch (algo) {
      case KdfId.argon2d:
      case KdfId.argon2id:
        parameters.addAll([
          ('P', ParameterType.uInt32, _defaultKdfParallelism),
          ('I', ParameterType.uInt64, _defaultKdfIterations),
          ('M', ParameterType.uInt64, _defaultKdfMemory),
          ('V', ParameterType.uInt32, _defaultKdfVersion)
        ]);
      case KdfId.aes:
        parameters.add(
          key: 'R',
          type: ParameterType.uInt64,
          value: Defaults.keyEncryptionRounds,
        );
      default:
        throw UnsupportedValueError('bad KDF algorithm');
    }

    return parameters;
  }

  static _readSignature(BytesReader reader) {
    if (reader.bytesLeft < 8) {
      throw FileCorruptedError('not enough data');
    }

    final sig1 = reader.readUint32();
    final sig2 = reader.readUint32();

    if (!(sig1 == Signatures.fileMagic && sig2 == Signatures.sig2Kdbx)) {
      throw FileCorruptedError('bad header signature');
    }
  }

  _readVersion(BytesReader reader) {
    final minor = reader.readUint16();
    final major = reader.readUint16();
    final v = (major, minor);

    if (!isVersionSupported(v)) {
      throw UnsupportedValueError('invalid version');
    }

    _version = v;
  }

  bool _readField(BytesReader reader, {bool isInner = false}) {
    final id = reader.readUint8();
    final size = _readFieldSize(reader);
    final bytes = reader.readBytes(size);

    if (isInner) {
      switch (_InnerField.values.elementAtOrNull(id)) {
        case _InnerField.innerRandomStreamID:
          crsAlgorithm =
              CrsAlgorithm.fromValue(BytesReader(bytes).readUint32());
        case _InnerField.innerRandomStreamKey:
          protectedStreamKey = bytes;
        case _InnerField.binary:
          _readBinary(bytes);
        case _InnerField.endOfHeader:
          return false;
        default:
          throw UnsupportedValueError('bad header field: $id');
      }
    } else {
      switch (_OuterField.values.elementAtOrNull(id)) {
        case _OuterField.innerRandomStreamID:
          crsAlgorithm =
              CrsAlgorithm.fromValue(BytesReader(bytes).readUint32());
        case _OuterField.endOfHeader:
          return false;
        case _OuterField.comment:
          // Not used
          break;
        case _OuterField.cipherID:
          dataCipherUuid = KdbxUuid.fromBytes(bytes);
        case _OuterField.compressionFlags:
          compression = _readCompressionFlags(bytes);
        case _OuterField.masterSeed:
          masterSeed = bytes;
        case _OuterField.transformSeed:
          transformSeed = bytes;
        case _OuterField.transformRounds:
          keyEncryptionRounds = BytesReader(bytes).readUint64();
        case _OuterField.encryptionIV:
          encryptionIV = bytes;
        case _OuterField.protectedStreamKey:
          protectedStreamKey = bytes;
        case _OuterField.streamStartBytes:
          streamStartBytes = bytes;
        case _OuterField.kdfParameters:
          kdfParameters = ParametersMap.fromBytes(bytes);
        case _OuterField.publicCustomData:
          publicCustomData = ParametersMap.fromBytes(bytes);
        default:
          throw UnsupportedValueError('bad header field: $id');
      }
    }

    return true;
  }

  _readBinary(List<int> bytes) {
    final view = ByteData.view(Uint8List.fromList(bytes).buffer);
    final isProtected = view.getUint8(0) & 0x1 != 0;
    final data = bytes.slice(1); // Actual data comes after the flag byte

    final binary = isProtected
        ? ProtectedBinary(protectedData: ProtectedData.fromBytes(data))
        : PlainBinary(data: data, compressed: false);

    binaries.add(binary);
  }

  _validate() {
    if (dataCipherUuid == null) {
      throw FileCorruptedError('no cipher in header');
    }
    if (masterSeed == null) {
      throw FileCorruptedError('no master seed in header');
    }
    if (encryptionIV == null) {
      throw FileCorruptedError('no encryption iv in header');
    }
    if (version.$1 < 4) {
      if (transformSeed == null) {
        throw FileCorruptedError('no transform seed in header');
      }
      if (keyEncryptionRounds == null) {
        throw FileCorruptedError('no key encryption rounds in header');
      }
      if (protectedStreamKey == null) {
        throw FileCorruptedError('no protected stream key in header');
      }
      if (streamStartBytes == null) {
        throw FileCorruptedError('no stream start bytes in header');
      }
      if (crsAlgorithm == null) {
        throw FileCorruptedError('no crs algorithm in header');
      }
    } else {
      if (kdfParameters == null) {
        throw FileCorruptedError('no kdf parameters in header');
      }
    }
  }

  int _readFieldSize(BytesReader reader) {
    return version.$1 >= 4 ? reader.readUint32() : reader.readUint16();
  }

  static CompressionAlgorithm _readCompressionFlags(List<int> bytes) {
    final reader = BytesReader(bytes);
    final id = reader.readUint32();

    if (id < 0 || id >= CompressionAlgorithm.values.length) {
      throw UnsupportedValueError('compression type');
    }

    return CompressionAlgorithm.values[id];
  }

  _validateInner() {
    if (protectedStreamKey == null) {
      throw FileCorruptedError('no protected stream key in header');
    }
    if (crsAlgorithm == null) {
      throw FileCorruptedError('no crs algorithm in header');
    }
  }

  _setHash(List<int> data) {
    _hash = SHA256Digest().process(Uint8List.fromList(data));
  }
}
