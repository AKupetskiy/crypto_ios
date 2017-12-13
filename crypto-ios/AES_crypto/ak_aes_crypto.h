//
//  ak_aes_crypto.h
//  crypto-ios
//
//  Created by Andrew Kupetskiy on 11/23/17.
//  Copyright © 2017 AndrewK. All rights reserved.
//

#ifndef ak_aes_crypto_h
#define ak_aes_crypto_h

#include <stddef.h>
#include <stdint.h>
#include "aes.h"

#define SHARED_SECRET_SIZE 32
#define SECRET_KEY_SIZE 16
#define NONCE_SIZE 13
#define TAG_SIZE 16
#define L_SIZE 2

typedef struct
{
    uint32_t counter;
    uint8_t nonce[NONCE_SIZE];
    cf_aes_context *ccm_ctx;
} ak_aes_context;

// -------------------------------------------------------------------

void ak_aes_init(ak_aes_context *ctx,
                 const uint8_t *shared_secret,
                 size_t shared_secret_size);

void ak_aes_encrypt(ak_aes_context *ctx,
                    const uint8_t *plain_data, size_t plain_data_size,
                    uint8_t *encrypted_data,
                    uint8_t *tag, size_t ntag);

int ak_aes_decrypt(ak_aes_context *ctx,
                   const uint8_t *encrypted_data, size_t encrypted_data_size,
                   const uint8_t *tag, size_t ntag,
                   uint8_t *plain_data);

void ak_aes_finish(ak_aes_context *ctx);

// -------------------------------------------------------------------

void ak_aes_encrypt_and_pack(ak_aes_context *ctx,
                             const uint8_t *plain_data, size_t plain_data_size,
                             uint8_t *package, uint8_t *package_size);

int ak_aes_unpack_and_decrypt(ak_aes_context *ctx,
                              const uint8_t *package, size_t package_size,
                              uint8_t *plain_data);

#endif /* ak_aes_crypto_h */
