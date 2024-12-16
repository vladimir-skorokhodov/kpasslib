import 'package:kpasslib/kpasslib.dart';

// TODO: improve the example

/// Creates a new database, modifies it, saves and loads again.
void main() async {
  final credentials = KdbxCredentials(
    password: ProtectedData.fromString('demo'),
    keyData: KdbxCredentials.createRandomKeyFile(version: 2),
  );

  var db = KdbxDatabase.create(
    credentials: credentials,
    name: 'Example',
  );

  final subGroup = db.createGroup(
    parent: db.root,
    name: 'Subgroup',
  );

  final entry = db.createEntry(parent: subGroup);

  entry.fields.addAll({
    'Title': KdbxTextField.fromText(text: 'Title'),
    'UserName': KdbxTextField.fromText(text: 'User'),
    'Password': KdbxTextField.fromText(
      text: 'Password',
      protected: true,
    ),
  });

  final binary = ProtectedBinary(
    protectedData: ProtectedData.fromString(
      'bin.txt content',
    ),
  );

  final reference = db.binaries.add(binary);
  entry.binaries['bin.txt'] = reference;

  entry.pushHistory();
  entry.fields.addAll({
    'Title': KdbxTextField.fromText(text: 'New title'),
    'UserName': KdbxTextField.fromText(text: 'New user'),
    'Password': KdbxTextField.fromText(
      text: 'New password',
      protected: true,
    ),
    'Custom': KdbxTextField.fromText(text: 'Custom'),
    'ProtectedCustom': KdbxTextField.fromText(
      text: 'Protected custom',
      protected: true,
    ),
  });
  entry.times.touch();

  final data = await db.save();
  db = await KdbxDatabase.fromBytes(
    data: data,
    credentials: credentials,
  );
}
