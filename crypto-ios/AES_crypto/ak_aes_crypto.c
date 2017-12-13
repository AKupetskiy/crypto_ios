//
//  ak_aes_crypto.c
//  crypto-ios
//
//  Created by Andrew Kupetskiy on 11/23/17.
//  Copyright © 2017 AndrewK. All rights reserved.
//

#include <stdio.h>

#include "ak_aes_crypto.h"
#include "modes.h"
#include "handy.h"
#include "tassert.h"

void append_counter_to_nonce(uint8_t *nonce, uint32_t counter) {
    uint8_t ctr_array[4];
    ctr_array[0] = counter >> 24;
    ctr_array[1] = counter >> 16;
    ctr_array[2] = counter >>  8;
    ctr_array[3] = counter;
    
    memcpy(nonce, ctr_array, 4);
}

//-----------------------------------------------------------------

void ak_aes_init(ak_aes_context *ctx,
                 const uint8_t *shared_secret,
                 size_t shared_secret_size) {
    memset(ctx, 0, sizeof *ctx);
    ctx->counter = 0;
    
    // init nonce from shared secret
    // nonce = shared_secret[19...31];
    memcpy(ctx->nonce, shared_secret+19, NONCE_SIZE);
    
    //then apply counter value onto it
    append_counter_to_nonce(ctx->nonce, ctx->counter);
        
    // init basic aes crypto
    cf_aes_context *ccm_context = (cf_aes_context *)malloc(sizeof(cf_aes_context));
    
    // pass secret key to it
    uint8_t secret_key[SECRET_KEY_SIZE];
    memcpy(secret_key, shared_secret, SECRET_KEY_SIZE);
    
    cf_aes_init(ccm_context, secret_key, SECRET_KEY_SIZE);
    
    ctx->ccm_ctx = ccm_context;
}

void ak_aes_finish(ak_aes_context *ctx)
{
    free(ctx->ccm_ctx);
    mem_clean(ctx, sizeof *ctx);
}

//----------------------------------------------------------------------

void ak_aes_encrypt(ak_aes_context *ctx,
                    const uint8_t *plain_data, size_t plain_data_size,
                    uint8_t *encrypted_data,
                    uint8_t *tag, size_t ntag) {
    
    //apply counter value onto it
    append_counter_to_nonce(ctx->nonce, ctx->counter);
    
    cf_ccm_encrypt(&cf_aes, ctx->ccm_ctx,
                   plain_data, plain_data_size, L_SIZE,
                   NULL, 0,
                   ctx->nonce, NONCE_SIZE,
                   encrypted_data,
                   tag, ntag);
    
    //increment counter
    ctx->counter = ctx->counter + 1;
}

int ak_aes_decrypt(ak_aes_context *ctx,
                   const uint8_t *encrypted_data, size_t encrypted_data_size,
                   const uint8_t *tag, size_t ntag,
                   uint8_t *plain_data) {
    
    int err = 0;
    err = cf_ccm_decrypt(&cf_aes, ctx->ccm_ctx,
                         encrypted_data, encrypted_data_size, L_SIZE,
                         NULL, 0,
                         ctx->nonce, NONCE_SIZE,
                         tag, ntag,
                         plain_data);
    
    //increment counter
    ctx->counter = ctx->counter + 1;
    
    return err;
}

// -------------------------------------------------------------------

void ak_aes_encrypt_and_pack(ak_aes_context *ctx,
                             const uint8_t *plain_data, size_t plain_data_size,
                             uint8_t *package, uint8_t *package_size) {
    uint8_t encrypted_data[plain_data_size], tag[TAG_SIZE];
    //apply counter value onto it
    
    ak_aes_encrypt(ctx, plain_data, plain_data_size, encrypted_data, tag, TAG_SIZE);
    
    // copy tag first
    memcpy(package, tag, TAG_SIZE);
    // then message
    memcpy(package + TAG_SIZE, encrypted_data, plain_data_size);
}

int ak_aes_unpack_and_decrypt(ak_aes_context *ctx,
                              const uint8_t *package, size_t package_size,
                              uint8_t *plain_data) {
    size_t encrypted_data_size = package_size - TAG_SIZE;
    uint8_t encrypted_data[encrypted_data_size], tag[TAG_SIZE];
    
    // copy tag first
    memcpy(tag, package, TAG_SIZE);
    // then message
    memcpy(encrypted_data,package + TAG_SIZE, encrypted_data_size);
    
    return ak_aes_decrypt(ctx, encrypted_data, encrypted_data_size, tag, TAG_SIZE, plain_data);
}

// --------------------------------------------------------------

