import 'package:convert/convert.dart';
import 'package:kpasslib/src/crypto/key_encryptor_aes.dart';
import 'package:test/test.dart';

void main() {
  group('KeyEncryptorAes unit tests', () {
    final data = hex.decode(
        '5d18f8a5ae0e7ea86f0ad817f0c0d40656ef1da6367d8a88508b3c13cec0d7af');
    final key = hex.decode(
        'ee66af917de0b0336e659fe6bd40a337d04e3c2b3635210fa16f28fb24d563ac');

    test('decrypts one round', () {
      final res = KeyEncryptorAes.transform(data: data, seed: key, rounds: 1);
      expect(hex.encode(res),
          'fbf9d1ab16cefd2840c56d829fe5aa2a23f72ac5b017226c3aa60d85b83ceabe');
    });

    test('decrypts two rounds', () {
      final res = KeyEncryptorAes.transform(data: data, seed: key, rounds: 2);
      expect(hex.encode(res),
          '3b4f244b4ffb049cc3d857abfd58a9e055ce96a9d53a8a2bf77822c2c4923df4');
    });

    test('decrypts many rounds', () {
      final res =
          KeyEncryptorAes.transform(data: data, seed: key, rounds: 10021);
      expect(hex.encode(res),
          'e7f84e62e366555cfda66f446271d9c7de953cc10333a0537c13cd2b583de4ad');
    });
  });
}
