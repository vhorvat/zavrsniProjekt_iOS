//
//  ViewController.swift
//  watchpstoryboard
//
//  Created by Viktor Horvat on 12.04.2022..
//

import UIKit
import CoreBluetooth
import UserNotifications
import Foundation


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var deviceNames = [String]()
    var centralManager: CBCentralManager!
    var myPeripheral: CBPeripheral!
    let notifCenter = UNUserNotificationCenter.current()
    var allBluetoothPeripherals = [CBPeripheral]()
    
    let arrayOfServices: [CBUUID] = [CBUUID(string:"1414")]
    let arrayOfProbabilities = ["No stimulus", "Wind", "Temperature", "Blue light", "Red light"]
    
    func scheduleNotification(){
        let content = UNMutableNotificationContent()
        content.title = "Watchplant AI"
        content.body = "New sensor is available"
        let date = Date().addingTimeInterval(1)
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let uuidString = UUID().uuidString
        
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        notifCenter.add(request) { (error) in
                }
    }
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            nameToShowLabel.text="Connecting"
            deviceNames.removeAll()
            central.scanForPeripherals(withServices: arrayOfServices, options: nil)
        case .unknown:
            nameToShowLabel.text="Unknown"
        case .resetting:
            nameToShowLabel.text="Resetting"
        case .unsupported:
            nameToShowLabel.text="Unsupported"
        case .unauthorized:
            nameToShowLabel.text="Unauthorized"
        case .poweredOff:
            nameToShowLabel.text="Powered off"
        @unknown default:
            nameToShowLabel.text="Error"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let pname = peripheral.name {
            deviceNames.append(pname)
            centralManager.stopScan()
            centralManager.connect(peripheral, options: nil)
            allBluetoothPeripherals.append(peripheral)
            scheduleNotification()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        nameToShowLabel.text="CONNECTED"
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("DEBUG: DEVICE SCANNED")
        print ("Services:\(String(describing : peripheral.services))")
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        peripheral.readValue(for: service.characteristics![0])
        peripheral.setNotifyValue(true, for: service.characteristics![0])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let value = [UInt8] (characteristic.value!)
        rawDataLabel.text = "NEED EDIT" //NEED EDIT
        interpretedDataLabel.text = arrayOfProbabilities[2] //NEED EDIT
        
    }

    @IBOutlet weak var interpretedDataLabel: UILabel!
    @IBOutlet weak var rawDataLabel: UILabel!
    @IBOutlet weak var nameToShowLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}