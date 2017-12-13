//
//  AKAESCrypto.m
//  crypto-ios
//
//  Created by Andrew Kupetskiy on 11/23/17.
//  Copyright © 2017 AndrewK. All rights reserved.
//

#import "AKAESCrypto.h"
#import "ak_aes_crypto.h"

@interface AKAESCrypto ()
@property (nonatomic, strong) NSData *secret;
@property (nonatomic, assign) ak_aes_context *aes_ccm_ctx;
@end

@implementation AKAESCrypto

- (instancetype)initWithSecret:(NSData *)secret {
    if ([secret length] != 32) {
        return nil;
    }
    
    if (self = [super init]) {
        _secret = secret;
        
        _aes_ccm_ctx = malloc(sizeof(ak_aes_context));
        ak_aes_init(_aes_ccm_ctx, [secret bytes], [secret length]);
    }
    
    return self;
}

- (void)dealloc {
    free(_aes_ccm_ctx);
}

- (NSData *)encryptWithData:(NSData *)data {
    size_t package_len = data.length + TAG_SIZE;
    uint8_t package[package_len];
    
    // magic in C func
    ak_aes_encrypt_and_pack(self.aes_ccm_ctx, data.bytes, data.length,package, package);
    
    // convert and send
    return [[NSData alloc] initWithBytes:package length:package_len];
}

- (NSData *)decryptWithData:(NSData *)encryptedData {
    size_t plain_data_len = encryptedData.length - TAG_SIZE;
    uint8_t plain_data[plain_data_len];
    
    // magic in C func
    int error = ak_aes_unpack_and_decrypt(self.aes_ccm_ctx, encryptedData.bytes, encryptedData.length, plain_data);
    
    if (error) {
        return nil;
    }
    // convert and send
    return [[NSData alloc] initWithBytes:plain_data length:plain_data_len];
    
    return nil;
}

+ (void)test_pack_unpack {
    uint8_t cipher[12+TAG_SIZE], decrypted[12];
    
    void *secret = "SxqlOW3UadPQMlo3pOVloA8Bk2MY9WYI";
    void *msg = "hello world\0";
    
    ak_aes_context ctx;
    ak_aes_init(&ctx, secret, 32);
    
    ak_aes_encrypt_and_pack(&ctx, msg, 12, cipher, 12 + TAG_SIZE);
    
    int err;
    err = ak_aes_unpack_and_decrypt(&ctx, cipher, 12+TAG_SIZE, decrypted);
    
    assert(err == 0);
    assert(memcmp(decrypted, msg, 12) == 0);
    
    cipher[0] ^= 0xff;
    err = ak_aes_unpack_and_decrypt(&ctx, cipher, 12+TAG_SIZE, decrypted);
    assert(err == 1);
    
}

+ (void)test_crypto_C_realisation {
    uint8_t cipher[12], tag[16], decrypted[12];
    
    void *secret = "SxqlOW3UadPQMlo3pOVloA8Bk2MY9WYI";
    void *msg = "hello world\0";
    
    ak_aes_context ctx;
    ak_aes_init(&ctx, secret, 32);
    
    ak_aes_encrypt(&ctx, msg, 12, cipher, tag, 16);
    
    int err;
    err = ak_aes_decrypt(&ctx, cipher, 12, tag, 16, decrypted);
    
    assert(err == 0);
    assert(memcmp(decrypted, msg, 12) == 0);
    
    tag[0] ^= 0xff;
    err = ak_aes_decrypt(&ctx, cipher, 12, tag, 16, decrypted);
    assert(err == 1);
    
    [self test_pack_unpack];
}

@end
