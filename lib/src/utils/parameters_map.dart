// ignore_for_file: public_member_api_docs

import 'dart:convert';

import 'package:collection/collection.dart';

import '../kdbx/kdbx_error.dart';
import 'byte_utils.dart';

/// Parameter types.
enum ParameterType {
  uInt32(0x04, 4),
  uInt64(0x05, 8),
  bool(0x08, 1),
  int32(0x0c, 4),
  int64(0x0d, 8),
  string(0x18, 0),
  bytes(0x42, 0);

  const ParameterType(this.id, this.size);

  /// The KDBX ID of the type.
  final int id;

  /// The size of the type in bytes.
  final int size;
}

/// A parameter with universal value.
class Parameter {
  /// The parameter type.
  final ParameterType type;

  /// The parameter value.
  final Object value;

  /// Constructs the [Parameter] with [type] and [value].
  Parameter({required this.type, required this.value});
}

/// A map of the string to [Parameter].
class ParametersMap {
  final Map<String, Parameter> _map = {};

  static const _maxSupportedVersion = 1;

  /// Constructs an empty [ParametersMap].
  ParametersMap();

  /// Constructs a [ParametersMap] packed into [bytes].
  factory ParametersMap.fromBytes(List<int> bytes) {
    final parameters = ParametersMap();
    final reader = BytesReader(bytes);
    reader.readUint8();
    final major = reader.readUint8();

    if (major <= 0 || major > _maxSupportedVersion) {
      throw UnsupportedValueError('invalid kdf version');
    }

    for (var entry = _readEntry(reader);
        reader.bytesLeft > 0 && entry != null;
        entry = _readEntry(reader)) {
      parameters._map.addEntries({entry});
    }

    return parameters;
  }

  /// Returns a value by [key].
  Object? get(String key) => _map[key]?.value;

  /// Appends a [Parameter] with [type] and [value] to the [key].
  add({
    required String key,
    required ParameterType type,
    required Object value,
  }) {
    final valid = switch (type) {
      ParameterType.uInt32 ||
      ParameterType.uInt64 ||
      ParameterType.int32 ||
      ParameterType.int64 =>
        value is int,
      ParameterType.bool => value is bool,
      ParameterType.string => value is String,
      ParameterType.bytes => value is List<int>
    };

    if (!valid) {
      throw UnsupportedValueError('invalid parameter type');
    }

    _map[key] = Parameter(type: type, value: value);
  }

  /// Appends all the parameters from [list].
  addAll(List<(String, ParameterType, Object)> list) {
    for (var item in list) {
      add(
        key: item.$1,
        type: item.$2,
        value: item.$3,
      );
    }
  }

  /// The packed parameters as a bytes sequence.
  List<int> get bytes {
    const defaultVersion = 0x0100;
    final writer = BytesWriter();
    writer.writeUint16(defaultVersion);
    for (var entry in _map.entries) {
      _writeEntry(writer, entry);
    }
    writer.writeUint8(0);
    return writer.bytes;
  }

  static MapEntry<String, Parameter>? _readEntry(BytesReader reader) {
    final id = reader.readUint8();
    if (id == 0) {
      return null;
    }

    final type = ParameterType.values.firstWhereOrNull((vt) => vt.id == id);
    if (type == null) {
      throw UnsupportedValueError('bad value type');
    }

    final keySize = reader.readInt32();
    if (keySize <= 0) {
      throw FileCorruptedError('bad key length');
    }
    final key = utf8.decode(reader.readBytes(keySize));

    final size = reader.readInt32();
    if (size < 0 || (type.size > 0 && type.size != size)) {
      throw FileCorruptedError('bad value length of ${type.id}');
    }
    final value = _readValue(reader: reader, type: type, size: size);

    return MapEntry(key, Parameter(type: type, value: value));
  }

  static Object _readValue(
      {required BytesReader reader,
      required ParameterType type,
      required int size}) {
    if (size < 0 || type.size > 0 && type.size != size) {
      throw FileCorruptedError('bad value length of ${type.id}');
    }

    return switch (type) {
      ParameterType.uInt32 => reader.readUint32(),
      ParameterType.uInt64 => reader.readUint64(),
      ParameterType.bool => reader.readUint8() > 0,
      ParameterType.int32 => reader.readInt32(),
      ParameterType.int64 => reader.readInt64(),
      ParameterType.string => utf8.decode(reader.readBytes(size)),
      ParameterType.bytes => reader.readBytes(size),
    };
  }

  _writeEntry(BytesWriter writer, MapEntry<String, Parameter> entry) {
    writer.writeUint8(entry.value.type.id);

    final keyBytes = utf8.encode(entry.key);
    writer.writeInt32(keyBytes.length);
    writer.writeBytes(keyBytes);

    switch (entry.value.type) {
      case ParameterType.uInt32:
        writer.writeInt32(4);
        writer.writeUint32(entry.value.value as int);
      case ParameterType.uInt64:
        writer.writeInt32(8);
        writer.writeUint64(entry.value.value as int);
      case ParameterType.bool:
        writer.writeInt32(1);
        writer.writeUint8(entry.value.value as bool ? 1 : 0);
      case ParameterType.int32:
        writer.writeInt32(4);
        writer.writeInt32(entry.value.value as int);
      case ParameterType.int64:
        writer.writeInt32(8);
        writer.writeInt64(entry.value.value as int);
      case ParameterType.string:
        final strBytes = utf8.encode(entry.value.value as String);
        writer.writeInt32(strBytes.length);
        writer.writeBytes(strBytes);
      case ParameterType.bytes:
        final bytes = entry.value.value as List<int>;
        writer.writeInt32(bytes.length);
        writer.writeBytes(bytes);
    }
  }
}
