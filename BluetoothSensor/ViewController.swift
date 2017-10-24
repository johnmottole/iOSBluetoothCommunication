//
//  ViewController.swift
//  BluetoothSensor
//
//  Created by John Mottole on 10/20/17.
//  Copyright © 2017 John Mottole. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    var manager:CBCentralManager!
    var peripheral:CBPeripheral!
    
    @IBOutlet weak var batteryLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var connectedLabel: UILabel!
    
    let BEAN_SCRATCH_UUID = CBUUID(string: "A495FF21-C5B1-4B44-B512-1370F02D74DE")
    let BEAN_SCRATCH_UUID2 = CBUUID(string: "A495FF22-C5B1-4B44-B512-1370F02D74DE")
    let BEAN_SERVICE_UUID = CBUUID(string: "A495FF20-C5B1-4B44-B512-1370F02D74DE")
    
    func setLabelConnected(connected : Bool)
    {
        if connected {
            connectedLabel.text = "Connected"
            connectedLabel.textColor = UIColor.green
        }else{
            connectedLabel.text = "Disconnected"
            tempLabel.text = ""
            batteryLabel.text = "Battery Level:"
            connectedLabel.textColor = UIColor.red
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLabelConnected(connected: false)
        manager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
            print("Scannin")
        } else {
            print("Bluetooth not available.")
        }
    }

    internal func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let device = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? NSString
        print(device)
        if device?.contains("JointTech") == true {
            self.manager.stopScan()
            self.peripheral = peripheral
            self.peripheral.delegate = self
            manager.connect(peripheral, options: nil)
            setLabelConnected(connected: true)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            let thisService = service as CBService
            print(service.uuid)
            if service.uuid == BEAN_SERVICE_UUID {
                peripheral.discoverCharacteristics(nil,for: thisService)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            let thisCharacteristic = characteristic as CBCharacteristic
            
            if thisCharacteristic.uuid == BEAN_SCRATCH_UUID || thisCharacteristic.uuid == BEAN_SCRATCH_UUID2 {
                self.peripheral.setNotifyValue(
                    true,
                    for: thisCharacteristic
                )
            }
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == BEAN_SCRATCH_UUID {
            let str = "\([UInt8](characteristic.value!)[0])"
            if let double = Double(str)
            {
                let far = double*9/5+32
                tempLabel.text = "\(far) F"
            }else{
                print("Cant make double")
            }
        }
        
        if characteristic.uuid == BEAN_SCRATCH_UUID2 {
            let str = "\([UInt8](characteristic.value!)[0])"
            if let percentage = Int(str)
            {
                batteryLabel.text = "Battery Level: \(percentage) %"
            }else{
                print("Cant make int")
            }
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        setLabelConnected(connected: false)
        manager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

