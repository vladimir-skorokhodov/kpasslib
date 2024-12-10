import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:kpasslib/kpasslib.dart';
import 'package:pointycastle/export.dart';
import 'package:xml/xml.dart';

import '../crypto/crypto_utils.dart';
import '../utils/xml_utils.dart';

/// A challenge response function type.
typedef KdbxChallengeResponse = List<int> Function(List<int> challenge);

/// A KDBX master key credentials
class KdbxCredentials {
  final ProtectedData? _passwordHash;
  final ProtectedData? _keyFileHash;
  final KdbxChallengeResponse? _challengeResponse;

  /// Constructs [KdbxCredentials] from [password], key file [keyData]
  /// and [challengeResponse].
  KdbxCredentials(
      {ProtectedData? password,
      List<int>? keyData,
      KdbxChallengeResponse? challengeResponse})
      : _passwordHash = _getPasswordHash(password),
        _keyFileHash = _getKeyFileHash(keyData),
        _challengeResponse = challengeResponse;

  /// The hash of the credentials without challenge response.
  get hash => getHash();

  /// The hash of the credentials with optional [challenge] response.
  List<int> getHash({List<int>? challenge}) {
    final challengeResp = getChallengeResponse(challenge);

    final allBytes = <int>[];
    final passwordHash = _passwordHash;
    final keyFileHash = _keyFileHash;

    if (passwordHash != null) {
      allBytes.addAll(passwordHash.bytes);
    }

    if (keyFileHash != null) {
      allBytes.addAll(keyFileHash.bytes);
    }

    if (challengeResp != null) {
      allBytes.addAll(challengeResp);
    }

    var hash = SHA256Digest().process(Uint8List.fromList(allBytes));
    CryptoUtils.wipeData(allBytes);
    return hash;
  }

  /// Calculates challenge response for requested [challenge].
  List<int>? getChallengeResponse(List<int>? challenge) {
    final response = _challengeResponse;
    if (response == null || challenge == null) {
      return null;
    }

    final result = response(challenge);
    final hash = SHA256Digest().process(Uint8List.fromList(result));
    CryptoUtils.wipeData(result);
    return hash;
  }

  /// Generates key file random data with provided [version].
  static List<int> createRandomKeyFile({required int version}) =>
      createKeyFileWithHash(
        bytes: CryptoUtils.randomBytes(32),
        version: version,
      );

  /// Constructs key file with provided [bytes] and [version].
  static List<int> createKeyFileWithHash(
      {required List<int> bytes, required int version}) {
    final versionString = version == 2 ? '2.0' : '1.00';
    final doc = XmlUtils.create('KeyFile', extraAttributes: '');
    final meta = XmlElement(
      XmlName(XmlElem.meta),
      [],
      [XmlElement(XmlName(XmlElem.version))..innerText = versionString],
    );
    final data = XmlElement(XmlName(XmlElem.data));

    if (version == 1) {
      data.innerText = base64.encode(bytes);
    } else {
      final hash = SHA256Digest().process(Uint8List.fromList(bytes));
      final hashString = hex.encode(hash.sublist(0, 4)).toUpperCase();
      final slices = bytes.slices(4).slices(4);
      final keyString = slices
          .map((e) => e
              .map((e) => hex.encode(e).toUpperCase())
              .fold('', (prev, e) => '$prev $e')
              .trim())
          .fold('', (prev, e) => '$prev\n      $e');

      data.attributes.add(XmlAttribute(XmlName(XmlAttr.hash), hashString));
      data.innerText = '$keyString\n';
    }

    final key = XmlElement(XmlName(XmlElem.key), [], [data]);
    doc.rootElement.children.addAll([meta, key]);

    return utf8.encode(doc.toXmlString(
      pretty: true,
      preserveWhitespace: (_) => true,
    ));
  }

  static ProtectedData? _getPasswordHash(ProtectedData? password) {
    return password == null ? null : ProtectedData.fromBytes(password.hash);
  }

  static ProtectedData? _getKeyFileHash(List<int>? keyData) {
    if (keyData == null) {
      return null;
    }

    var keyDataStr = '';

    try {
      keyDataStr = utf8.decode(keyData);
      final xml = XmlDocument.parse(keyDataStr);
      final meta = xml.rootElement.getElement(XmlElem.meta);
      if (meta == null) {
        throw UnsupportedValueError('xml key-file without meta element');
      }

      final version = meta.getElement(XmlElem.version);
      if (version == null) {
        throw UnsupportedValueError('xml key-file without version element');
      }
      final majorVersion = version.innerText.split('.').first.trim();

      final key = xml.rootElement.getElement(XmlElem.key);
      if (key == null) {
        throw UnsupportedValueError('xml key-file without key element');
      }

      final data = key.getElement(XmlElem.data);
      if (data == null) {
        throw UnsupportedValueError('xml key-file without data element');
      }

      switch (majorVersion) {
        case '1':
          return ProtectedData.fromBytes(base64.decode(data.innerText));
        case '2':
          final keyFileData =
              hex.decode(data.innerText.replaceAll(RegExp('\\s+'), ''));
          final keyFileDataHash = data.getAttribute(XmlAttr.hash);
          if (keyFileDataHash != null) {
            final computedHash =
                SHA256Digest().process(Uint8List.fromList(keyFileData));
            final computedHashStr = hex.encode(computedHash.sublist(0, 4));
            if (computedHashStr.toUpperCase() !=
                keyFileDataHash.toUpperCase()) {
              throw FileCorruptedError('xml key-file data hash mismatch');
            }
          }
          return ProtectedData.fromBytes(keyFileData);

        default:
          throw UnsupportedValueError('xml key-file version');
      }
    } on KdbxError catch (_) {
      rethrow;
    } catch (_) {}

    if (keyDataStr.length == 64) {
      try {
        final bytes = hex.decode(keyDataStr);
        return ProtectedData.fromBytes(bytes);
      } catch (_) {}
    }

    if (keyData.length == 32) {
      return ProtectedData.fromBytes(keyData);
    }

    final hash = SHA256Digest().process(Uint8List.fromList(keyData));
    return ProtectedData.fromBytes(hash);
  }
}
