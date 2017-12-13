//
//  BTTTransportService.swift
//  crypto-ios
//
//  Created by Andrew Kupetskiy on 12/10/17.
//  Copyright © 2017 AndrewK. All rights reserved.
//

import Foundation

enum connectionState:String {
    case disabled
    case disconnected
    case connected
    case searchingPeripheral
    case establishingSecureConnection
    case secureConnect
}

protocol Transportable {
    associatedtype DataType
    
    func sendData(_ data:DataType) -> Bool
}

protocol BTTransportServiceDelegate:class {
    func service(_ service: BTTransportService, didChangeState state:connectionState)
    func service(_ service: BTTransportService, didReceivedData data:String)
}

class BTTransportService: Transportable, BTConversationDelegate {
    private let btDevice: BTCentralDevice
    private let marshaller: StringMarshaller
    private let cryptoService: BTCryptoService
    
    weak var delegate: BTTransportServiceDelegate?
    var state: connectionState = .disabled {
        didSet {
            self.delegate?.service(self, didChangeState: state)
        }
    }
    
    init(btDevice: BTCentralDevice, cryptoService: BTCryptoService, marshaller: StringMarshaller) {
        self.btDevice = btDevice
        self.cryptoService = cryptoService
        self.marshaller = marshaller
        
        self.btDevice.delegate = self
    }
    
    //MARK: - main calls
    func connectToBTDevice() {
        if btDevice.start() {
            state = .searchingPeripheral
        } else {
            state = .disconnected
        }
    }
    
    func instantiateSecureConnection() {
        state = .establishingSecureConnection
        let publicKey = cryptoService.getLocalPubKey()
        btDevice.sendPubKey(publicKey)
    }
    
    //MARK: - transportable
    func sendData(_ data: String) -> Bool {
        
        let newData = marshaller.marshall(data)
        if let encryptedData = cryptoService.encryptData(newData) {
            btDevice.sendData(encryptedData)
            return true
        }
        
        return false
    }
    
    //MARK: - BTConversationDelegate
    func device(_ device: BTWorkable, didStartWorking started: Bool) {
        if started {
            state = .disconnected
        } else {
            state = .disabled
        }
    }
    
    func device(_ device: BTWorkable, didConnectedToPeriptheral connected: Bool) {
        if connected {
            state = .connected
        } else {
            state = .disconnected
        }
    }
    
    func device(startedSearchingPeripherals device: BTWorkable) {
        state = .searchingPeripheral
    }
    
    func device(_ device: BTWorkable, didReceived bytes: Data) {
        //unmarshall
        
        if let decryptedData = cryptoService.decryptData(bytes) {
            let message = marshaller.unmarshall(decryptedData)
            
            self.delegate?.service(self, didReceivedData: message)
        }
    }
    
    func device(_ device: BTWorkable, receivedPubKey key: Data) {
        cryptoService.importRemotePubKey(key)
        
        let signature = cryptoService.prepareLocalSignature()
        btDevice.sendSignature(signature)
    }
    
    func device(_ device: BTWorkable, receivedPubKeySignature signature: Data) {
        if cryptoService.verifyRemoteSignature(signature) {
            cryptoService.calculateSharedSecret()
            state = .secureConnect
        }
    }
}
