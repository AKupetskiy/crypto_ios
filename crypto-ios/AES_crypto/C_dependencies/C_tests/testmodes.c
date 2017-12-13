/*
 * cifra - embedded cryptography library
 * Written in 2014 by Joseph Birr-Pixton <jpixton@gmail.com>
 *
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software. If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

#include "testmodes.h"
#include "aes.h"
#include "modes.h"
#include "gf128.h"
#include "stdio.h"

#include "handy.h"
#include "tassert.h"

void calc_ccm(const void *key, size_t nkey,
              const void *header, size_t nheader,
              const void *plain, size_t nplain,
              const void *nonce, size_t nnonce,
              const void *expect_cipher, size_t ncipher,
              const void *expect_tag, size_t ntag) {
    uint8_t cipher[32], tag[16], decrypted[32];
    
    cf_aes_context ctx;
    cf_aes_init(&ctx, key, nkey);
    
    cf_ccm_encrypt(&cf_aes, &ctx,
                   plain, nplain, 15 - nnonce,
                   header, nheader,
                   nonce, nnonce,
                   cipher,
                   tag, ntag);
    
    assert(memcmp(tag, expect_tag, ntag) == 0);
    assert(memcmp(cipher, expect_cipher, ncipher) == 0);
    
    int err;
    err = cf_ccm_decrypt(&cf_aes, &ctx,
                         expect_cipher, ncipher, 15 - nnonce,
                         header, nheader,
                         nonce, nnonce,
                         tag, ntag,
                         decrypted);
    assert(err == 0);
    assert(memcmp(decrypted, plain, nplain) == 0);
    
    tag[0] ^= 0xff;
    
    err = cf_ccm_decrypt(&cf_aes, &ctx,
                         expect_cipher, ncipher, 15 - nnonce,
                         header, nheader,
                         nonce, nnonce,
                         tag, ntag,
                         decrypted);
    assert(err == 1);
}

void check_ccm(const void *key, size_t nkey,
               const void *header, size_t nheader,
               const void *plain, size_t nplain,
               const void *nonce, size_t nnonce,
               const void *expect_cipher, size_t ncipher,
               const void *expect_tag, size_t ntag)
{
    printf("\ntest = \n");
    printf("key = %s\n",(char *)key);
    printf("header = %s\n",(char *)header);
    printf("plain = %s\n",(char *)plain);
    printf("nonce = %s\n",(char *)nonce);
    printf("expect_cipher = %s\n",(char *)expect_cipher);
    printf("expect_tag = %s\n",(char *)expect_tag);
    
    printf("\n");
    
    calc_ccm(key, nkey, header, nheader, plain, nplain, nonce, nnonce, expect_cipher, ncipher, expect_tag, ntag);
}

void test_ccm(void)
{
  check_ccm("\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf", 16,
            "\x00\x01\x02\x03\x04\x05\x06\x07", 8,
            "\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e", 23,
            "\x00\x00\x00\x03\x02\x01\x00\xa0\xa1\xa2\xa3\xa4\xa5", 13,
            "\x58\x8c\x97\x9a\x61\xc6\x63\xd2\xf0\x66\xd0\xc2\xc0\xf9\x89\x80\x6d\x5f\x6b\x61\xda\xc3\x84", 23,
            "\x17\xe8\xd1\x2c\xfd\xf9\x26\xe0", 8);
//
//  check_ccm("\x40\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f", 16,
//            "\x00\x01\x02\x03\x04\x05\x06\x07", 8,
//            "\x20\x21\x22\x23", 4,
//            "\x10\x11\x12\x13\x14\x15\x16", 7,
//            "\x71\x62\x01\x5b", 4,
//            "\x4d\xac\x25\x5d", 4);
//
//  check_ccm("\x40\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f", 16,
//            "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13", 20,
//            "\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33\x34\x35\x36\x37", 24,
//            "\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b", 12,
//            "\xe3\xb2\x01\xa9\xf5\xb7\x1a\x7a\x9b\x1c\xea\xec\xcd\x97\xe7\x0b\x61\x76\xaa\xd9\xa4\x42\x8a\xa5", 24,
//            "\x48\x43\x92\xfb\xc1\xb0\x99\x51", 8);
    
}


