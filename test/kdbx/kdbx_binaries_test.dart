import 'package:kpasslib/kpasslib.dart';
import 'package:test/test.dart';

void main() {
  group('Binaries unit tests', () {
    final protectedValue = ProtectedData.fromString('bin');
    final protectedValue2 = ProtectedData.fromString('another');
    const hash =
        '51a1f05af85e342e3c849b47d387086476282d5f50dc240c19216d6edfb1eb5a';
    const hash2 =
        'ae448ac86c4e8e4dec645729708ef41873ae79c6dff84eff73360989487f08e5';

    test('adds a ProtectedValue', () {
      final binaries = KdbxBinaries();
      final binary = ProtectedBinary(protectedData: protectedValue);
      binaries.add(binary);
      expect(binary.hash, hash);
      expect(binaries.all, [binary]);
    });

    test('adds a binary and generates id', () {
      final binaries = KdbxBinaries();
      final binary = ProtectedBinary(protectedData: protectedValue);
      final binary2 = ProtectedBinary(protectedData: protectedValue2);
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
      final binary = ProtectedBinary(protectedData: protectedValue);
      final binary2 = ProtectedBinary(protectedData: protectedValue2);
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
  });
}
