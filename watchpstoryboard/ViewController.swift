//
//  ViewController.swift
//  watchpstoryboard
//
//  Created by Viktor Horvat on 12.04.2022..
//

import UIKit
import CoreBluetooth
import CoreLocation
import UserNotifications
import Foundation


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet var tableView: UITableView!
    var deviceNames = [String]()
    var centralManager: CBCentralManager!
    var myPeripheral: CBPeripheral!
    let notifCenter = UNUserNotificationCenter.current()
    var allBluetoothPeripherals = [CBPeripheral]()
    
    let arrayOfServices: [CBUUID] = [CBUUID(string:"1414")]
    
    var currentConnectedName = "NULL"
    
    func scheduleNotification(){
        let content = UNMutableNotificationContent()
        content.title = "Watchplant"
        content.body = "Dostupan je novi senzor u blizini"
        let date = Date().addingTimeInterval(1)
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let uuidString = UUID().uuidString
        
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        notifCenter.add(request) { (error) in
                }
        print("NOTIFIKACIJA!")
    }
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("BLE STATE ON")
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
            print (pname)
            deviceNames.append(pname)
            centralManager.stopScan()
            centralManager.connect(peripheral, options: nil)
            allBluetoothPeripherals.append(peripheral)
            scheduleNotification()
            print("DEBUG:_________________________")
            print(advertisementData)
            print("_________________________")
            print(deviceNames)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected")
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
        print("DEBUG: Uređaj:\(peripheral) i servis na njemu: \(service)")
        peripheral.readValue(for: service.characteristics![0])
        peripheral.setNotifyValue(true, for: service.characteristics![0])
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let value = [UInt8] (characteristic.value!)
        print (value)
    }

    @IBOutlet weak var pressureToShowLabel: UILabel!
    @IBOutlet weak var humidityToShowLabel: UILabel!
    @IBOutlet weak var nameToShowLabel: UILabel!
    @IBOutlet weak var temperatureToShowLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)

    }
}
