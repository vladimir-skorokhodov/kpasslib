import 'package:convert/convert.dart';
import 'package:kpasslib/kpasslib.dart';
import 'package:kpasslib/src/utils/parameters_map.dart';
import 'package:test/test.dart';

void main() {
  group('ParametersMap unit tests', () {
    const data =
        '00010808000000426f6f6c5472756501000000010809000000426f6f6c46616c'
        '73650100000000040600000055496e743332040000002a000000050600000055'
        '496e74363408000000ffffeeeeddddcccc0c05000000496e74333204000000d6'
        'ffffff0d05000000496e74363408000000444433332222111118060000005374'
        '72696e670b000000537472696e6756616c756542090000004279746541727261'
        '7907000000000102030405ff00';
    test('reads and writes dictionary', () {
      final params = ParametersMap.fromBytes(hex.decode(data));
      expect(params.get('BoolTrue'), true);
      expect(params.get('BoolFalse'), false);
      expect(params.get('UInt32'), 42);
      expect(params.get('UInt64'), 0xccccddddeeeeffff);
      expect(params.get('Int32'), -42);
      expect(params.get('Int64'), 0x1111222233334444);
      expect(params.get('String'), 'StringValue');
      expect(
          hex.encode(params.get('ByteArray') as List<int>), '000102030405ff');
      expect(hex.encode(params.bytes), data);
    });

    test('writes dictionary', () {
      final params = ParametersMap()
        ..addAll([
          ('BoolTrue', ParameterType.bool, true),
          ('BoolFalse', ParameterType.bool, false),
          ('UInt32', ParameterType.uInt32, 42),
          ('UInt64', ParameterType.uInt64, 0xccccddddeeeeffff),
          ('Int32', ParameterType.int32, -42),
          ('Int64', ParameterType.int64, 0x1111222233334444),
          ('String', ParameterType.string, 'StringValue'),
          ('ByteArray', ParameterType.bytes, hex.decode('000102030405ff')),
        ]);
      expect(hex.encode(params.bytes), data);
    });

    test('returns undefined for not found value', () {
      final params = ParametersMap();
      expect(params.get('val'), null);
    });

    test('allows to add key twice', () {
      final params = ParametersMap()
        ..addAll([
          ('UInt32', ParameterType.uInt32, 42),
          ('UInt32', ParameterType.uInt32, 43),
        ]);
      expect(params.get('UInt32'), 43);
    });

    test('throws error for empty version', () {
      expect(
          () => ParametersMap.fromBytes(hex.decode('0000')),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('kdf version'))));
    });

    test('throws error for larger version', () {
      expect(
          () => ParametersMap.fromBytes(hex.decode('0002')),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('kdf version'))));
    });

    test('throws error for bad value type', () {
      expect(
          () => ParametersMap.fromBytes(hex.decode('0001ff01000000dd10000000')),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('bad value type'))));
    });

    test('reads empty dictionary', () {
      ParametersMap.fromBytes(hex.decode('000100'));
    });

    test('throws error for bad key length', () {
      expect(
          () => ParametersMap.fromBytes(hex.decode('00010400000000dd10000000')),
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('bad key length'))));
    });

    test('throws error for bad value length', () {
      expect(
          () => ParametersMap.fromBytes(hex.decode('0001040100000000ffffffff')),
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('bad value length'))));
    });

    test('throws error for bad uint32 value', () {
      expect(
          () =>
              ParametersMap.fromBytes(hex.decode('00010401000000000500000000')),
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('bad value length'))));
    });

    test('throws error for bad uint64 value', () {
      expect(
          () =>
              ParametersMap.fromBytes(hex.decode('00010501000000000500000000')),
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('bad value length'))));
    });

    test('throws error for bad bool value', () {
      expect(
          () =>
              ParametersMap.fromBytes(hex.decode('00010801000000000500000000')),
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('bad value length'))));
    });

    test('throws error for bad int32 value', () {
      expect(
          () =>
              ParametersMap.fromBytes(hex.decode('00010c01000000000500000000')),
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('bad value length'))));
    });

    test('throws error for bad int64 value', () {
      expect(
          () =>
              ParametersMap.fromBytes(hex.decode('00010d01000000000500000000')),
          throwsA(predicate((e) =>
              e is FileCorruptedError &&
              e.message.contains('bad value length'))));
    });

    test('throws error for bad int32 on set', () {
      expect(
          () => ParametersMap().add(
                key: 'val',
                type: ParameterType.int32,
                value: 'str',
              ),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('invalid parameter type'))));
    });

    test('throws error for bad int64 on set', () {
      expect(
          () => ParametersMap().add(
                key: 'val',
                type: ParameterType.int64,
                value: 'str',
              ),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('invalid parameter type'))));
    });

    test('throws error for bad bool on set', () {
      expect(
          () => ParametersMap().add(
                key: 'val',
                type: ParameterType.bool,
                value: 'true',
              ),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('invalid parameter type'))));

      expect(
          () => ParametersMap().add(
                key: 'val',
                type: ParameterType.bool,
                value: 1,
              ),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('invalid parameter type'))));
    });

    test('throws error for bad uint32 on set', () {
      expect(
          () => ParametersMap().add(
                key: 'val',
                type: ParameterType.uInt32,
                value: 'str',
              ),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('invalid parameter type'))));
    });

    test('throws error for bad uint64 on set', () {
      expect(
          () => ParametersMap().add(
                key: 'val',
                type: ParameterType.uInt64,
                value: 'str',
              ),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('invalid parameter type'))));
    });

    test('throws error for bad string on set', () {
      expect(
          () => ParametersMap().add(
                key: 'val',
                type: ParameterType.string,
                value: 123,
              ),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('invalid parameter type'))));
    });

    test('throws error for bad bytes', () {
      expect(
          () => ParametersMap().add(
                key: 'val',
                type: ParameterType.bytes,
                value: '000',
              ),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('invalid parameter type'))));

      expect(
          () => ParametersMap().add(
                key: 'val',
                type: ParameterType.bytes,
                value: 123,
              ),
          throwsA(predicate((e) =>
              e is UnsupportedValueError &&
              e.message.contains('invalid parameter type'))));
    });
  });
}
