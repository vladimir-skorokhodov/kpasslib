# kreepto

This directory contains a standalone Rust-based native library that exports the FFI symbols used by Dart crypto:

- `argon2_hash(...)`
- `aes256_transform_block(...)`
- `aes256_encrypt_cbc(...)`
- `aes256_decrypt_cbc(...)`
- `chacha20_transform(...)`
- `salsa20_transform(...)`

## Build

Requires Rust toolchain with `cargo`.

```sh
cd native/kreepto-rust
cargo build --release
```

The produced library name depends on the platform:

- macOS/iOS: `target/release/libkreepto.dylib`
- Linux/Android: `target/release/libkreepto.so`
- Windows: `target/release/kreepto.dll`

## Public symbols

- `argon2_hash(...)`
- `aes256_transform_block(...)`
- `aes256_encrypt_cbc(...)`
- `aes256_decrypt_cbc(...)`
- `chacha20_transform(...)`
- `salsa20_transform(...)`

## Notes

- This crate is a standalone Rust library.
- It is designed as a drop-in standalone library for later integration into Dart FFI.
