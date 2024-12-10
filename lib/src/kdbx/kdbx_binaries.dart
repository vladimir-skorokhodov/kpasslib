import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:kpasslib/kpasslib.dart';
import 'package:pointycastle/export.dart';
import 'package:xml/xml.dart';

import '../crypto/crypto_utils.dart';
import '../utils/xml_utils.dart';

/// A KDBX binary attachment.
abstract class KdbxBinary {
  KdbxBinary._();

  /// Constructs a KDBX binary from an XML [element].
  /// Requires KDBX [header] to access salt generator for encrypted binaries.
  /// Throws [FileCorruptedError] in case reference couldn't be parsed.
  factory KdbxBinary.fromXml({
    required XmlElement element,
    required KdbxHeader header,
  }) {
    final refAttribute = element.getAttribute(XmlAttr.ref);
    if (refAttribute != null) {
      final id = int.tryParse(refAttribute);
      if (id == null) {
        throw FileCorruptedError('Incorrect binary reference');
      }
      return BinaryReference(id);
    }

    var bytes = base64.decode(element.innerText).toList();
    final compressed =
        XmlUtils.getBooleanAttribute(element, XmlAttr.compressed);

    if (compressed) {
      bytes = gzip.decode(bytes);
    }

    if (XmlUtils.getBooleanAttribute(element, XmlAttr.protected)) {
      return ProtectedBinary(
        protectedData: ProtectedData.fromProtectedBytes(
          bytes: bytes,
          salt: header.saltGenerator.getSalt(bytes.length),
        ),
      );
    }

    if (XmlUtils.getBooleanAttribute(element, XmlAttr.protectedInMemory)) {
      return ProtectedBinary(protectedData: ProtectedData.fromBytes(bytes));
    }

    return PlainBinary(data: bytes, compressed: compressed);
  }
}

/// A reference to a KDBX binary attachment.
class BinaryReference extends KdbxBinary {
  /// The numeric ID of the referencing binary.
  int id;

  /// Constructs a [BinaryReference] referenced to [id].
  BinaryReference(this.id) : super._();

  /// Serializes binary to XML element for a KDBX entry field with [key].
  XmlElement toXml(String key) => XmlElement(XmlName(XmlElem.binary), [], [
        XmlElement(XmlName(XmlElem.key))..innerText = key,
        XmlElement(XmlName(XmlElem.value))
          ..setAttribute(XmlAttr.ref, id.toString())
      ]);
}

/// A KDBX binary attachment with data.
abstract class KdbxDataBinary extends KdbxBinary {
  String? _hash;

  KdbxDataBinary._() : super._();

  /// The data contained in the binary.
  List<int> get data;

  /// The hash string of the [data] to identify and compare content of the binary.
  String get hash {
    return _hash ??= switch (this) {
      final ProtectedBinary b => hex.encode(b.protectedData.hash),
      _ => hex.encode(SHA256Digest().process(Uint8List.fromList(data))),
    };
  }

  @override
  operator ==(Object other) => other is KdbxDataBinary && hash == other.hash;

  @override
  int get hashCode => hash.hashCode;

  XmlElement _toXml({
    required int id,
    KdbxHeader? header,
  }) =>
      XmlElement(XmlName(XmlElem.binary), [
        XmlAttribute(XmlName(XmlAttr.id), id.toString()),
      ]);
}

/// A KDBX binary attachment with plain data.
class PlainBinary extends KdbxDataBinary {
  @override
  final List<int> data;

  /// Whether the data is compressed with gzip.
  bool compressed;

  /// Constructs a [PlainBinary] containing the [data].
  /// If [compressed], the data will be serialized in gzip format.
  PlainBinary({required this.data, required this.compressed}) : super._();

  @override
  XmlElement _toXml({
    required int id,
    KdbxHeader? header,
  }) {
    return super._toXml(id: id)
      ..setAttribute(XmlAttr.compressed, compressed ? 'True' : 'False')
      ..innerText = base64.encode(compressed ? gzip.encode(data) : data);
  }
}

/// A KDBX binary attachment with encrypted data.
class ProtectedBinary extends KdbxDataBinary {
  /// The protected data of the binary.
  final ProtectedData protectedData;

  /// Constructs a [ProtectedBinary] containing the [protectedData].
  ProtectedBinary({required this.protectedData}) : super._();

  @override
  List<int> get data => protectedData.bytes;

  @override
  XmlElement _toXml({
    required int id,
    KdbxHeader? header,
  }) {
    if (header == null) {
      return super._toXml(id: id)
        ..setAttribute(XmlAttr.protected, 'False')
        ..setAttribute(XmlAttr.protectedInMemory, 'True')
        ..innerText = base64.encode(data);
    }

    return super._toXml(id: id)
      ..setAttribute(XmlAttr.protected, 'True')
      ..innerText = base64.encode(
        CryptoUtils.transformXor(
          data: data,
          salt: header.saltGenerator.getSalt(data.length),
        ),
      );
  }
}

/// Collection of KDBX binaries.
class KdbxBinaries {
  final _map = <int, KdbxDataBinary>{};

  /// The list of all data binaries, contained in the [KdbxBinaries].
  List<KdbxDataBinary> get all => _map.values.toList();

  /// The list of references to [all].
  List<BinaryReference> get allAsRefs =>
      _map.keys.map((id) => BinaryReference(id)).toList();

  /// Inserts the [binary].
  /// Returns [BinaryReference] to the inserted [KdbxDataBinary].
  BinaryReference add(KdbxDataBinary binary) {
    final found = _map.entries.firstWhereOrNull((e) => e.value == binary);

    if (found != null) {
      return BinaryReference(found.key);
    }

    final id = _map.length;
    _map[id] = binary;

    return BinaryReference(id);
  }

  /// Removes the [binary] by it's hash.
  remove(KdbxDataBinary binary) => _map.removeWhere(
        (key, value) => value == binary,
      );

  /// Removes all the binaries, not included into the [usedBinaries].
  cleanup(List<BinaryReference> usedBinaries) {
    final ids = usedBinaries.map((b) => b.id).toSet();
    _map.removeWhere((id, _) => !ids.contains(id));
  }

  /// Returns true if binaries contains the [binary].
  bool contains(KdbxDataBinary binary) => _map.containsValue(binary);

  /// Returns KdbxDataBinary by the [reference].
  KdbxDataBinary? getByRef(BinaryReference reference) => _map[reference.id];

  /// Appends the binaries by reading XML [element].
  /// Decrypts protected data with salt generator from the [header].
  readFromXml({
    required XmlElement element,
    required KdbxHeader header,
  }) {
    for (var e in element.childElements) {
      if (e.qualifiedName == XmlElem.binary) {
        final id = e.getAttribute(XmlAttr.id);
        final binary = KdbxBinary.fromXml(element: e, header: header);

        if (id != null) {
          if (binary is! KdbxDataBinary) {
            throw FileCorruptedError('binary reference in meta');
          }

          try {
            _map[int.parse(id)] = binary;
          } on FormatException catch (e) {
            throw FileCorruptedError('cannot read id: $id. ${e.message}');
          }
        }
      }
    }
  }

  /// Serializes the binaries structure into XML element.
  /// If [header] is not null, encrypts the protected values.
  XmlElement toXml(KdbxHeader? header) {
    return XmlElement(
      XmlName(XmlElem.binaries),
      [],
      all.mapIndexed((i, e) => e._toXml(id: i, header: header)),
    );
  }
}
