# KPassLib

[![Dart](https://github.com/korovan-software/kpasslib/actions/workflows/dart.yml/badge.svg)](https://github.com/korovan-software/kpasslib/actions/workflows/dart.yml)
[![Coverage Status](https://coveralls.io/repos/github/korovan-software/kpasslib/badge.svg?branch=main)](https://coveralls.io/github/korovan-software/kpasslib?branch=main)
[![Pub](https://img.shields.io/pub/v/kpasslib.svg)](https://pub.dev/packages/kpasslib)

KPassLib is a Dart library for reading, modifying and writing [KeePass](https://keepass.info) v2 databases (KDBX version 3 or 4).
Ported and refactored from [KdbxWeb](https://github.com/keeweb/kdbxweb).

## Features

- no native addons
- fast encryption with [pointycastle](https://github.com/bcgit/pc-dart)
- full support of KDBX features
- protected values are stored in memory XOR'ed with a salt
- conflict-free merge support
- high code test coverage
- Dart 3 with sound null-safety

## Compatibility

Supports KDBX version 3 and 4, current KeePass file format. Old KDB files (for KeePass v1) are out of scope.

## Usage

### Loading

```dart
final credentials = KdbxCredentials(
  password: ProtectedData.fromString('demo'),
  keyData: demoKey,
  challengeResponse: challengeResponse,
);
final db1 = KdbxDatabase.fromBytes(
  data: TestResources.demoKdbx,
  credentials: credentials,
);
final db2 = KdbxDatabase.fromXmlString(
  xmlString: xml,
  credentials: credentials,
);
```

### Saving

```dart
final data = db.save();
final xmlString = db.exportToXmlString(pretty: true);
```

You can also pretty-print XML:

```dart
final prettyXml = db.exportToXmlString(pretty: true);
```

### Changing credentials

```dart
final db = KdbxDatabase.fromBytes(
  data: TestResources.demoKdbx,
  credentials: KdbxCredentials(
    password: ProtectedData.fromString('demo'),
  ),
);
db.header.credentials = KdbxCredentials(
  password: ProtectedData.fromString('new password'),
);
final data = db.save();
```

### A database creation

```dart
final db = KdbxDatabase.create(
  credentials: credentials,
  name: 'Example',
);
final subGroup = db.createGroup(
  parent: db.root,
  name: 'Subgroup',
);
final entry = db.createEntry(parent: subGroup);
```

### Maintenance

```dart
db.cleanup(
  history: true,
  icons: true,
  binaries: true,
);

// upgrade to the latest version (currently KDBX 4)
db.upgrade();

// downgrade to KDBX 3
db.version = (3, 1);

// set KDF to AES
db.kdf = KdfId.aes;
```

### Merge

Entries, groups and meta are consistent against merging in any direction with any state.

Due to format limitations, entry history merging and some non-critical fields in meta can produce phantom records or deletions, so correct entry history merging is supported only with one central replica. Items order is not guaranteed but the algorithm tries to preserve it.

```dart
// load local database
var db = KdbxDatabase.fromBytes(
  data: localData,
  credentials: credentials,
);

// work with database and save it
db.save();

// save local editing state
var state = db.localEditState.toXml().toXmlString();

// reopen the database
db = KdbxDatabase.fromBytes(
  data: fileData,
  credentials: credentials,
);

// assign edit state obtained before save
db.localEditState = KdbxEditState.fromXml(
  XmlDocument.parse(state).firstChild,
);

// work with database

// load remote db
final remote = KdbxDatabase.fromBytes(
  data: remoteData,
  credentials: credentials,
);

// merge remote into local
db.merge(remote);

// save local db
final data = db.save();
db.clearLocalEditState();
```

### Groups

```dart
final root = db.root;
final anotherGroup = db.root.allItems.firstWhereOrNull(
  (item) => item.uuid == id
);
final deepGroup = db.root.groups[1].groups[2];
```

### A group creation

```dart
final group = db.createGroup(
  parent: db.root,
  name: 'New group',
);

final anotherGroup = db.createGroup(
  parent: group,
  name: 'Subgroup',
);
```

### An item deletion

```dart
db.remove(group);
```

### An item move

```dart
db.move(item: group, target: toGroup);
db.move(item: group, target: toGroup, index: atIndex);
```

### A recycle bin

```dart
final recycleBin = db.recycleBin;
```

### Recursive traverse

```dart
db.root.allEntries.forEach((e){/* ... */});
db.root.allGroups.forEach((g){/* ... */});
db.root.allItems.forEach((i){/* ... */});
```

### Entries

```dart
final entry = db.root.entries.first;
entry.fields['AccountNumber'] = KdbxTextField.fromText(
  text: '1234 5678',
);
entry.fields['PIN'] = KdbxTextField.fromText(
  text: '4321',
  protected: true,
);
```

### An entry creation

```dart
final entry = db.createEntry(parent: group);
```

### An entry modification

```dart
// push current state to history stack
entry.pushHistory();

// change something
entry.foreground = '#ff0000';

// update entry modification and access time
entry.times.touch();

// remove states from entry history
entry.removeFromHistory(start: 0, end: 5);
```

Important: don't modify history states directly, this will break merge.

### An entry import

If you're moving an entry from another file, this is called _import_:

```dart
db.importEntry(
  entry: entry,
  target: toGroup,
  other: sourceFile
);
```

### A protected data

Used for passwords and custom fields, stored the value in memory XOR'ed

```dart
final value = ProtectedData.fromProtectedBytes(bytes: value, salt: salt);
final valueFromString = ProtectedData.fromString('str');
final valueFromBinary = ProtectedData.fromBytes(data);
final textString = valueFromString.text;
final binaryData = valueFromBinary.bytes;
```

### Errors

```dart
try {
  KdbxDatabase.fromBytes(
    data: data,
    credentials: credentials,
  );
} on FileCorruptedError catch (e) {
  /// ...
}
```

## Running tests and generation of code coverage

### Running the tests

Use VS code Testing tab or use terminal command:

```bash
dart test
```

### Code coverage report

Use terminal command:

```bash
dart test --coverage=coverage
dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
genhtml coverage/lcov.info -o coverage/
```
