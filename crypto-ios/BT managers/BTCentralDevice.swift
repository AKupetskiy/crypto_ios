//
//  BTCentralDevice.swift
//  crypto-ios
//
//  Created by Andrew Kupetskiy on 9/19/17.
//  Copyright © 2017 AndrewK. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BTSearchable {
    func startSearch() -> Bool
    func stopSearch()
}

class BTCentralDevice: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, BTSearchable {
    weak var delegate: BTConversationDelegate?
    fileprivate var centralManager: CBCentralManager!
    fileprivate var peripheral: CBPeripheral?
    
    fileprivate var pubKeyCharacteristic: CBCharacteristic!
    fileprivate var signatureCharacteristic: CBCharacteristic!
    fileprivate var encryptedDataCharacteristic: CBCharacteristic!
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func sendData(_ data: Data) {
        peripheral?.writeValue(data, for: encryptedDataCharacteristic, type: .withResponse)
    }
    
    func sendPubKey(_ key: Data) {
        peripheral?.writeValue(key, for: pubKeyCharacteristic, type: .withResponse)
    }
    
    func sendSignature(_ signature: Data) {
        peripheral?.writeValue(signature, for: signatureCharacteristic, type: .withResponse)
    }
    
    func stopSearch() {
        if let peripheral = peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        peripheral = nil
        pubKeyCharacteristic = nil
        signatureCharacteristic = nil
        encryptedDataCharacteristic = nil
        
        self.delegate?.device(self, didConnectedToPeriptheral: false)
    }
    
    func startSearch() -> Bool {
        let on = centralManager.state == .poweredOn
        if on {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            self.delegate?.device(startedSearchingPeripherals: self)
        }
        
        return on
    }
    
    func getCharacteristic(forUUID uuidString: String) -> CBCharacteristic? {
        switch uuidString {
        case UUIDValues.pubKeyUUID:
            return self.pubKeyCharacteristic
        case UUIDValues.encryptedDataUUID:
            return self.encryptedDataCharacteristic
        case UUIDValues.signatureUUID:
            return self.signatureCharacteristic
        default:
            return nil
        }
    }
}

//MARK: - CBCentralManager delegate

extension BTCentralDevice {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("state: \(central.state)")
        
        let on = centralManager.state == .poweredOn
        delegate?.device(self, didStartWorking: on)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("peripheral: \(peripheral)")
        
        if advertisementData[CBAdvertisementDataLocalNameKey] as? String == "BLE_DGSC" {
            central.stopScan()
            self.peripheral = peripheral
            
            if let p = self.peripheral {
                central.connect(p, options: nil)
            }
        }
    }
    
    // Called when it succeeded
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("successfully connected to \(peripheral)!")
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    // Called when it failed
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("failed to connect to \(peripheral)")
        self.delegate?.device(self, didConnectedToPeriptheral: false)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if self.peripheral == peripheral {
            self.peripheral = nil
            self.delegate?.device(self, didConnectedToPeriptheral: false)
            
            let when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when) { [unowned self] in
                self.centralManager.scanForPeripherals(withServices: nil, options: nil)
                self.delegate?.device(startedSearchingPeripherals: self)
            }
            
        }
    }
}

//MARK: - CBPeripheral delegate

extension BTCentralDevice {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("error: \(error)")
            return
        }
        guard let services = peripheral.services else {
            self.delegate?.device(self, didConnectedToPeriptheral: false)
            return
        }
        
        print("Found \(services.count) services!")
        
        services.forEach { (service) in
            print(service)
        }
        
        let updServices: [CBService] = services.filter { (srvs) -> Bool in
            return srvs.uuid.isEqual(CBUUID(string: UUIDValues.serviceUUID))
        }
        
        if let service = updServices.first  {
            // start looking for first service
            print("start discovering service: \(service)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            self.delegate?.device(self, didConnectedToPeriptheral: false)
            print("error: \(error)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            self.delegate?.device(self, didConnectedToPeriptheral: false)
            return
        }
        
        print("Found \(characteristics.count) characteristics!")
        
        characteristics.forEach { characteristic in
            switch characteristic.uuid.uuidString {
            case UUIDValues.pubKeyUUID:
                self.pubKeyCharacteristic = characteristic
            case UUIDValues.encryptedDataUUID:
                self.encryptedDataCharacteristic = characteristic
            case UUIDValues.signatureUUID:
                self.signatureCharacteristic = characteristic
            default:
                self.delegate?.device(self, didConnectedToPeriptheral: false)
                return
            }
        }
        
        self.delegate?.device(self, didConnectedToPeriptheral: true)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Failed… error: \(error)")
            return
        }
        
        if let value = characteristic.value {
            switch characteristic.uuid.uuidString {
            case UUIDValues.pubKeyUUID:
                delegate?.device(self, receivedPubKey: value)
            case UUIDValues.encryptedDataUUID:
                delegate?.device(self, didReceived: value)
            case UUIDValues.signatureUUID:
                delegate?.device(self, receivedPubKeySignature: value)
            default:
                return
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("error: \(error)")
            return
        }
        
        let chr = getCharacteristic(forUUID: characteristic.uuid.uuidString)!
        peripheral.readValue(for: chr)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("error: \(error)")
        }
        else {
            print("isNotifying: \(characteristic.isNotifying)")
        }
    }
}
