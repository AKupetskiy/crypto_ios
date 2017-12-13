//
//  BTProtocols.swift
//  crypto-ios
//
//  Created by Andrew Kupetskiy on 10/16/17.
//  Copyright © 2017 AndrewK. All rights reserved.
//

import Foundation

protocol BTConversationDelegate: class {
    func device(_ device: BTWorkable, didStartWorking started:Bool)
    func device(startedSearchingPeripherals device: BTWorkable)
    func device(_ device: BTWorkable, didConnectedToPeriptheral connected:Bool)
    func device(_ device: BTWorkable, didReceived bytes:Data)
    
    func device(_ device: BTWorkable, receivedPubKey key:Data)
    func device(_ device: BTWorkable, receivedPubKeySignature signature:Data)
}

protocol BTWorkable {
    func start() -> Bool
    func stop()
}

extension BTCentralDevice: BTWorkable {
    func start() -> Bool {
        return startSearch()
    }
    
    func stop() {
        stopSearch()
    }
}

struct UUIDValues {
    static let serviceUUID = "CBCB"
    
    static let pubKeyUUID = "CBC1"
    static let encryptedDataUUID = "CBC2"
    static let signatureUUID = "CBC3"
}
