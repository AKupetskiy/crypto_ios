//
//  ViewController.swift
//  crypto-ios
//
//  Created by Andrew Kupetskiy on 9/19/17.
//  Copyright © 2017 AndrewK. All rights reserved.
//

import UIKit
import Security

class ViewController: UIViewController, BTTransportServiceDelegate {
    @IBOutlet weak var sendDataButton: UIButton!
    @IBOutlet weak var initSecureConnectButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var statusView: UIView!
    
    var transportService: BTTransportService!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)

        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.black.withAlphaComponent(0.5).cgColor

        initTransportService()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.transportService.connectToBTDevice()
        }
    }
    
    @objc func hideKeyboard() {
        textView.resignFirstResponder()
    }
    
    func initTransportService() {
        
        let BTDevice = BTCentralDevice()
        let cryptoService = BTCryptoService()
        let marshaller = StringMarshaller()
        
        transportService = BTTransportService(btDevice: BTDevice, cryptoService: cryptoService, marshaller: marshaller)
        transportService.delegate = self
        
        configureButtons()
    }
    
    func configureButtons() {
        sendDataButton.isHidden = true
        sendDataButton.isEnabled = false
        textView.isHidden = true
        statusView.backgroundColor = UIColor.gray
        initSecureConnectButton.isEnabled = false
    }
    
    @IBAction func startSecureConnection(button: UIButton) {
        transportService.instantiateSecureConnection()
    }
    
    @IBAction func sendPressed(button: UIButton) {
        transportService.sendData(textView.text)
    }
    
    func service(_ service: BTTransportService, didChangeState state: connectionState) {
        switch state {
        case .disabled:
            configureButtons()
        case .disconnected:
            sendDataButton.isHidden = true
            sendDataButton.isEnabled = false
            textView.isHidden = true
            statusView.backgroundColor = UIColor.red
            initSecureConnectButton.isEnabled = false
            initSecureConnectButton.isHidden = false
        case .connected:
            sendDataButton.isHidden = false
            sendDataButton.isEnabled = false
            textView.isHidden = true
            statusView.backgroundColor = UIColor.green.withAlphaComponent(0.5)
            initSecureConnectButton.isEnabled = true
            initSecureConnectButton.isHidden = false
        case .searchingPeripheral:
            sendDataButton.isHidden = true
            sendDataButton.isEnabled = false
            textView.isHidden = true
            statusView.backgroundColor = UIColor.blue.withAlphaComponent(0.5)
            initSecureConnectButton.isEnabled = false
            initSecureConnectButton.isHidden = false
        case .establishingSecureConnection:
            sendDataButton.isHidden = false
            sendDataButton.isEnabled = false
            textView.isHidden = true
            statusView.backgroundColor = UIColor.blue
            initSecureConnectButton.isEnabled = false
            initSecureConnectButton.isHidden = true
        case .secureConnect:
            sendDataButton.isHidden = false
            sendDataButton.isEnabled = true
            textView.isHidden = false
            statusView.backgroundColor = UIColor.orange
            initSecureConnectButton.isEnabled = false
            initSecureConnectButton.isHidden = true
        }
    }
    
    func service(_ service: BTTransportService, didReceivedData data: String) {
        textView.text = "newData: " + data
    }
}

extension Data {
    var hexValue: String { return self.map {String(format: "%02hhx", $0)}.joined() }
}
