//
//  DHCrypto.swift
//  crypto-ios
//
//  Created by Andrew Kupetskiy on 11/17/17.
//  Copyright © 2017 AndrewK. All rights reserved.
//

import Foundation

class DHCrypto {
    private (set) var crypter: GMEllipticCurveCrypto!
    private (set) var remoteCrypter: GMEllipticCurveCrypto!
    
    var localUnCompressedPubKey: Data?
    var remotePubKey: Data?
    
    var pubKeyValid = false
    
    private(set) var secret: Data!
    
    init() {
        crypter = GMEllipticCurveCrypto.generateKeyPair(for: GMEllipticCurveSecp256r1)
        localUnCompressedPubKey = crypter.decompressPublicKeyWithoutPadding(crypter.publicKey!)
    }
    
    func importSignature(_ signature:Data) {
        if let pubKey = remotePubKey {
            let remoteCrypter = GMEllipticCurveCrypto(curve: GMEllipticCurveSecp256r1)!
            remoteCrypter.publicKey = pubKey
            
            pubKeyValid = remoteCrypter.hashSHA256AndVerifySignature(signature, for: pubKey)
        }
    }
    
    func prepareLocalSignature() -> Data {
        return crypter.hashSHA256AndSign(localUnCompressedPubKey!)!
    }

    func calculateSecret() {
        if let pubKey = remotePubKey {
            secret = crypter.sharedSecret(forPublicKey: pubKey)
        }
    }
}
