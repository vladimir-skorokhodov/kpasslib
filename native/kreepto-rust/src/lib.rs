use aes::cipher::{BlockCipherDecrypt, BlockCipherEncrypt, KeyInit};
use aes::{Aes256, Block};
use argon2::{Algorithm, Argon2, Params, Version};
use chacha20::cipher::{KeyIvInit, StreamCipher, StreamCipherSeek};
use chacha20::ChaCha20;
use salsa20::cipher::{
    NewCipher, StreamCipher as Salsa20StreamCipher, StreamCipherSeek as Salsa20StreamCipherSeek,
};
use salsa20::Salsa20;
use std::convert::TryFrom;
use std::slice;

const AES_BLOCK_SIZE: usize = 16;
const AES_KEY_SIZE: usize = 32;
const CHACHA20_KEY_SIZE: usize = 32;
const CHACHA20_NONCE_SIZE: usize = 12;
const SALSA20_KEY_SIZE: usize = 32;
const SALSA20_NONCE_SIZE: usize = 8;

fn slice_from_ptr<'a>(ptr: *const u8, len: usize) -> &'a [u8] {
    unsafe { slice::from_raw_parts(ptr, len) }
}

fn slice_from_mut_ptr<'a>(ptr: *mut u8, len: usize) -> &'a mut [u8] {
    unsafe { slice::from_raw_parts_mut(ptr, len) }
}

fn aes_block_from_slice(chunk: &mut [u8]) -> Block {
    Block::from(<[u8; AES_BLOCK_SIZE]>::try_from(chunk).unwrap())
}

#[no_mangle]
pub extern "C" fn aes256_transform_block(data: *mut u8, key: *const u8, rounds: u64) {
    if data.is_null() || key.is_null() {
        return;
    }

    let block = slice_from_mut_ptr(data, AES_BLOCK_SIZE);
    let key = slice_from_ptr(key, AES_KEY_SIZE);

    let cipher = Aes256::new_from_slice(key).unwrap();
    let mut block_data = aes_block_from_slice(block);
    for _ in 0..rounds {
        cipher.encrypt_block(&mut block_data);
    }
    block.copy_from_slice(&block_data);
}

#[no_mangle]
pub extern "C" fn aes256_encrypt_cbc(data: *mut u8, data_len: u32, key: *const u8, iv: *const u8) {
    if data.is_null() || key.is_null() || iv.is_null() {
        return;
    }

    let data_len = data_len as usize;
    if data_len % AES_BLOCK_SIZE != 0 {
        return;
    }

    let data = slice_from_mut_ptr(data, data_len);
    let key = slice_from_ptr(key, AES_KEY_SIZE);
    let iv = slice_from_ptr(iv, AES_BLOCK_SIZE);

    let cipher = Aes256::new_from_slice(key).unwrap();
    let mut previous = iv.to_owned();

    for chunk in data.chunks_exact_mut(AES_BLOCK_SIZE) {
        for i in 0..AES_BLOCK_SIZE {
            chunk[i] ^= previous[i];
        }
        let mut block = aes_block_from_slice(chunk);
        cipher.encrypt_block(&mut block);
        chunk.copy_from_slice(&block);
        previous.copy_from_slice(chunk);
    }
}

#[no_mangle]
pub extern "C" fn aes256_decrypt_cbc(data: *mut u8, data_len: u32, key: *const u8, iv: *const u8) {
    if data.is_null() || key.is_null() || iv.is_null() {
        return;
    }

    let data_len = data_len as usize;
    if data_len % AES_BLOCK_SIZE != 0 {
        return;
    }

    let data = slice_from_mut_ptr(data, data_len);
    let key = slice_from_ptr(key, AES_KEY_SIZE);
    let iv = slice_from_ptr(iv, AES_BLOCK_SIZE);

    let cipher = Aes256::new_from_slice(key).unwrap();
    let mut previous = iv.to_owned();

    for chunk in data.chunks_exact_mut(AES_BLOCK_SIZE) {
        let current_block = chunk.to_owned();
        let mut block = aes_block_from_slice(chunk);
        cipher.decrypt_block(&mut block);
        for i in 0..AES_BLOCK_SIZE {
            chunk[i] = block[i] ^ previous[i];
        }
        previous.copy_from_slice(&current_block);
    }
}

#[no_mangle]
pub extern "C" fn chacha20_transform(
    data: *mut u8,
    data_len: u32,
    key: *const u8,
    nonce: *const u8,
    counter: u32,
) {
    if data.is_null() || key.is_null() || nonce.is_null() {
        return;
    }

    let data_len = data_len as usize;
    let data = slice_from_mut_ptr(data, data_len);
    let key = slice_from_ptr(key, CHACHA20_KEY_SIZE);
    let nonce = slice_from_ptr(nonce, CHACHA20_NONCE_SIZE);

    let mut cipher = ChaCha20::new_from_slices(key, nonce).unwrap();
    cipher.seek((counter as u64) << 6);
    cipher.apply_keystream(data);
}

#[no_mangle]
pub extern "C" fn salsa20_transform(
    data: *mut u8,
    data_len: u32,
    key: *const u8,
    nonce: *const u8,
    counter: u64,
) {
    if data.is_null() || key.is_null() || nonce.is_null() {
        return;
    }

    let data_len = data_len as usize;
    let data = slice_from_mut_ptr(data, data_len);
    let key = slice_from_ptr(key, SALSA20_KEY_SIZE);
    let nonce = slice_from_ptr(nonce, SALSA20_NONCE_SIZE);

    let mut cipher = Salsa20::new_from_slices(key, nonce).unwrap();
    cipher.seek(counter << 6);
    cipher.apply_keystream(data);
}

#[no_mangle]
pub extern "C" fn argon2_hash(
    password: *const u8,
    password_len: u32,
    salt: *const u8,
    salt_len: u32,
    parallelism: u32,
    memory_size_kb: u32,
    iterations: u32,
    hash_len: u32,
    type_: u32,
    version: u32,
    output: *mut u8,
) -> i32 {
    if password.is_null() || salt.is_null() || output.is_null() {
        return -1;
    }

    let password = slice_from_ptr(password, password_len as usize);
    let salt = slice_from_ptr(salt, salt_len as usize);
    let output = slice_from_mut_ptr(output, hash_len as usize);

    let algorithm = match type_ {
        0 => Algorithm::Argon2d,
        2 => Algorithm::Argon2id,
        _ => return -1,
    };

    let version = match version {
        0x10 => Version::V0x10,
        0x13 => Version::V0x13,
        _ => return -1,
    };

    let params = match Params::new(
        memory_size_kb,
        iterations,
        parallelism,
        Some(hash_len as usize),
    ) {
        Ok(params) => params,
        Err(_) => return -1,
    };

    let argon2 = Argon2::new(algorithm, version, params);

    match argon2.hash_password_into(password, salt, output) {
        Ok(_) => 0,
        Err(_) => -1,
    }
}
