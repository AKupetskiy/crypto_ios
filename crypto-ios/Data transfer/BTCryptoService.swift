//
//  BTCryptoService.swift
//  crypto-ios
//
//  Created by Andrew Kupetskiy on 12/10/17.
//  Copyright © 2017 AndrewK. All rights reserved.
//

import Foundation

protocol SecretKeyEstablishmentProtocol {
    func getLocalPubKey() -> Data
    func importRemotePubKey(_ key:Data)
    func prepareLocalSignature() -> Data
    func verifyRemoteSignature(_ signature: Data) -> Bool
    func calculateSharedSecret()
}

class BTCryptoService: SecretKeyEstablishmentProtocol {
    private let dh =  DHCrypto()
    private var aesCCM: AKAESCrypto?
    
    var canEncrypt:Bool {
        if aesCCM != nil {
            return true
        } else {
            return false
        }
    }
    
    func encryptData(_ plainData:Data) -> Data? {
        guard let ccm = aesCCM else {
            return nil
        }
        
        return ccm.encrypt(with: plainData)
    }
    
    func decryptData(_ encryptedData: Data) -> Data? {
        guard let ccm = aesCCM else {
            return nil
        }
        
        return ccm.decrypt(with: encryptedData)
    }
    
    private func initCCM() {
        aesCCM = AKAESCrypto(secret: dh.secret)
    }
    
    //MARK: ECDHProtocol
    func getLocalPubKey() -> Data {
        print("localPubKey = " + dh.crypter.publicKey.hexValue)
        return dh.crypter.publicKey!
    }
    
    func importRemotePubKey(_ key: Data) {
        dh.remotePubKey = key
        print("remote PubKey = " + key.hexValue)
    }
    
    func prepareLocalSignature() -> Data {
        return dh.prepareLocalSignature()
    }
    
    func verifyRemoteSignature(_ signature: Data) -> Bool {
        print("remote signature = " + signature.hexValue)
        dh.importSignature(signature)
        
        return dh.pubKeyValid
    }
    
    func calculateSharedSecret() {
        if dh.pubKeyValid {
            dh.calculateSecret()
            print("secret = " + dh.secret.hexValue)
            
            initCCM()
        }
    }
}
