# KPassLib changelog

## 1.1.3

- Added KDBX 4 timestamp compatibility for empty and ISO 8601 values.
- Fixed reading the `protected` flag for KDBX 4 binary attachments.
- Fixed KDBX 3 XML element order (`Meta` before `Root`) to preserve protected fields when `ProtectedBinary` is present.
- Respected `binaryTime` when serializing `LastModificationTime` in KDBX 4.1 `CustomData` and `CustomIcons`.
- Extended `xml` dependency support to `>=6.2.2 <8.0.0` and updated dependencies.

## 1.1.2

- Exported `CryptoFfi` from main library import.

## 1.1.1

- General improvements.

## 1.1.0

- Improved cryptography performance.
- Added pure Dart implementations of AES, ChaCha20, Salsa20, and Argon2.
- Added Rust implementations of AES, ChaCha20, Salsa20, and Argon2, and integrated them using FFI.
- Removed third-party dependencies for cryptographic operations.

## 1.0.8

- Fixed _KdbxDatabase.getGroup()_ method.
- Fixed _KdbxBinaries_ inconsistency.

## 1.0.7

- Minor fixes.

## 1.0.6

- Fixed KDBX4 incompatibility with KeePass Desktop.
- General improvements.

## 1.0.5

- Improved performance.

## 1.0.4

- Renamed _Icon_ enum to _KdbxIcon_.

## 1.0.3

- Removed _meta_ dependency.

## 1.0.2

- Support Web platform.

## 1.0.1

- Minor fix.

## 1.0.0

- Initial version.
