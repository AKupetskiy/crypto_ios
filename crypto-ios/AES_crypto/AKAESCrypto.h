//
//  AKAESCrypto.h
//  crypto-ios
//
//  Created by Andrew Kupetskiy on 11/23/17.
//  Copyright © 2017 AndrewK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AKAESCrypto : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithSecret:(NSData *)secret;

- (NSData *)encryptWithData:(NSData *)data;
- (NSData *)decryptWithData:(NSData *)encryptedData;


// DEBUG only!!!!
+ (void)test_crypto_C_realisation;

@end
