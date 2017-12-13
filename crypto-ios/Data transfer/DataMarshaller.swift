//
//  DataMarshaller.swift
//  crypto-ios
//
//  Created by Andrew Kupetskiy on 12/10/17.
//  Copyright © 2017 AndrewK. All rights reserved.
//

import Foundation

protocol DataMarshallable {
    associatedtype T
    
    func marshall(_ value: T) -> Data
    func unmarshall(_ data:Data) -> T
}


class StringMarshaller: DataMarshallable {
    func marshall(_ value: String) -> Data {
        let newValue = value + "\0"
        
        guard let data = newValue.data(using: .utf8) else {
            return Data()
        }
        
        return data
    }
    
    func unmarshall(_ data: Data) -> String {
        
        guard let string = String(bytes: data, encoding: String.Encoding.utf8) else {
            return ""
        }
        
        return string
    }
}
