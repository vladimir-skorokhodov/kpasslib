import 'package:kpasslib/kpasslib.dart';
import 'package:test/test.dart';

void main() {
  group('Binaries unit tests', () {
    final protected = ProtectedData.fromString('bin');
    final protected2 = ProtectedData.fromString('another');
    const hash =
        '51a1f05af85e342e3c849b47d387086476282d5f50dc240c19216d6edfb1eb5a';
    const hash2 =
        'ae448ac86c4e8e4dec645729708ef41873ae79c6dff84eff73360989487f08e5';

    test('adds a protected binary', () {
      final binaries = KdbxBinaries();
      final binary = ProtectedBinary(protectedData: protected);
      binaries.add(binary);
      expect(binary.hash, hash);
      expect(binaries.all, [binary]);
    });

    test('adds a binary and generates id', () {
      final binaries = KdbxBinaries();
      final binary = ProtectedBinary(protectedData: protected);
      final binary2 = ProtectedBinary(protectedData: protected2);
      binaries.add(binary);
      binaries.add(binary2);

      final found1 = binaries.getByRef(BinaryReference(0));
      expect(found1!.hash, hash);

      final found2 = binaries.getByRef(BinaryReference(1));
      expect(found2!.hash, hash2);

      final notFound = binaries.getByRef(BinaryReference(2));
      expect(notFound, null);
    });

    test('returns a binary by reference', () {
      final binaries = KdbxBinaries();
      final binary = ProtectedBinary(protectedData: protected);
      final binary2 = ProtectedBinary(protectedData: protected2);
      binaries.add(binary);
      binaries.add(binary2);

      binaries.remove(binary2);

      final found1 = binaries.getByRef(BinaryReference(0));
      expect(found1!.hash, hash);

      var notFound = binaries.getByRef(BinaryReference(1));
      expect(notFound, null);

      notFound = binaries.getByRef(BinaryReference(2));
      expect(notFound, null);
    });

    test('removes a binary by reference', () {
      final binaries = KdbxBinaries();
      final binary1 = PlainBinary(data: [1], compressed: false);
      final binary2 = PlainBinary(data: [2], compressed: false);
      final binary3 = PlainBinary(data: [3], compressed: false);

      binaries.add(binary1);
      binaries.add(binary2);
      binaries.add(binary3);
      expect(binaries.all, [binary1, binary2, binary3]);

      binaries.remove(binary2);
      expect(binaries.all, [binary1, binary3]);

      binaries.add(binary2);
      expect(binaries.contains(binary1), true);
      expect(binaries.contains(binary2), true);
      expect(binaries.contains(binary3), true);
    });

    test('removes a binary by reference', () {
      final binaries = KdbxBinaries();
      final binary1 = PlainBinary(data: [1], compressed: false);
      final binary2 = PlainBinary(data: [2], compressed: false);
      final binary3 = PlainBinary(data: [3], compressed: true);

      final ref1 = binaries.add(binary1);
      final ref2 = binaries.add(binary2);
      final ref3 = binaries.add(binary3);
      expect(binaries.getByRef(ref1)?.data, [1]);
      expect(binaries.getByRef(ref2)?.data, [2]);
      expect(binaries.getByRef(ref3)?.data, [3]);

      binaries.remove(binary2);
      expect(binaries.getByRef(ref2), null);
      expect(binaries.getByRef(ref1)?.data, [1]);
      expect(binaries.getByRef(ref3)?.data, [3]);

      final ref4 = binaries.add(binary2);
      expect(binaries.getByRef(ref2), null);
      expect(binaries.getByRef(ref1)?.data, [1]);
      expect(binaries.getByRef(ref3)?.data, [3]);
      expect(binaries.getByRef(ref4)?.data, [2]);
    });
  });
}
